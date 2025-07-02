{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.programs.containerization.podman;
  # TODO: Find a way to use /var/run/podman.sock instead. Permissions are a pain.
  podmanSymLinkSocketPath = "/tmp/podman.sock";
in
{
  options.${namespace}.programs.containerization.podman = {
    enable = mkEnableOption "podman";
    overrideDockerSocket = mkBoolOpt false "Whether or not to override the docker socket.";
    autoStart = mkBoolOpt false "Whether or not to automatically start the podman machine.";
  };

  config = mkIf cfg.enable {
    environment.variables = lib.mkIf cfg.overrideDockerSocket {
      DOCKER_HOST = "unix://${podmanSymLinkSocketPath}";
    };

    launchd.user.agents =
      let
        name = "podman-manager";
        username = config.${namespace}.user.name;
      in
      {
        ${name}.serviceConfig = {
          Label = name;
          Program = "${
            pkgs.writeShellApplication {
              inherit name;
              runtimeInputs = [ pkgs.podman ];
              text = ''
                # Run the podman command as another user using sudo
                PODMAN_SOCKET_PATH=$(command podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}')

                if [ -z "$PODMAN_SOCKET_PATH" ]; then
                  echo "Podman socket path not found"
                  exit 1
                fi

                if [ ! -e "${podmanSymLinkSocketPath}" ] && ln -s "$PODMAN_SOCKET_PATH" "${podmanSymLinkSocketPath}"; then
                  echo "Symlink created: ${podmanSymLinkSocketPath} -> $PODMAN_SOCKET_PATH"
                fi
              '';
              # TODO: the autoStart option is not working as expected
              # ${lib.optionalString cfg.autoStart ''
              #   # Start the podman machine on boot
              #   if ! command podman machine list --format "{{.LastUp}}" | grep -q "running"; then
              #     command podman machine start
              #   fi
              # ''}
            }
          }/bin/${name}";
          UserName = username;
          RunAtLoad = true;
          StandardErrorPath = "${config.users.users.${username}.home}/Library/Logs/podman/${name}.err.log";
          StandardOutPath = "${config.users.users.${username}.home}/Library/Logs/podman/${name}.out.log";
        };
      };
  };
}
