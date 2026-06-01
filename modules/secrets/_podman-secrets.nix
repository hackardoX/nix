{
  lib,
  pkgs,
  config,
  ...
}:
let
  uid = config.flake.meta.users.hal.uid;
in
{
  options.services.podman.containers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, config, ... }:
        {
          options.secrets = lib.mkOption {
            type = lib.types.attrsOf lib.types.path;
            default = { };
            example = lib.literalExpression ''
              {
                DB_PASSWORD = config.programs.onepassword-secrets.secretPaths.db_password;
                API_KEY     = config.programs.onepassword-secrets.secretPaths.api_key;
              }
            '';
            description = ''
              Secrets to inject as environment variables into the container.
              Each key becomes an environment variable whose value is the
              content of the specified file, read at container start time
              via the systemd ExecStartPre hook.
            '';
          };

          config = lib.mkIf (config.secrets != { }) {
            environmentFile = [
              "/run/user/${toString uid}/podman-secrets/${name}"
            ];

            extraConfig.Service.ExecStartPre = [
              (lib.getExe (
                pkgs.writeShellApplication {
                  name = "podman-secrets-${name}";
                  runtimeInputs = [ pkgs.coreutils ];
                  text = ''
                    install -D -m 600 /dev/null "/run/user/${toString uid}/podman-secrets/${name}"
                    {
                    ${lib.concatStringsSep "\n" (
                      lib.mapAttrsToList (envName: path: ''echo "${envName}=$(<${path})"'') config.secrets
                    )}
                    } > "/run/user/${toString uid}/podman-secrets/${name}"
                  '';
                }
              ))
            ];
          };
        }
      )
    );
  };
}
