{ config, lib, ... }:
let
  polyModule = {
    services.onepassword-secrets.secrets.koofrPassword = {
      path = "/run/secrets/koofr/password";
      reference = "op://Homelab/Rclone remotes/Koofr/password";
      group = "rclone";
      mode = "0440";
    };
  };
in
{
  flake.modules.nixos.rclone = polyModule;
  flake.modules.darwin.rclone = polyModule;

  flake.modules.homeManager.rclone =
    hmArgs@{ osConfig, ... }:
    {
      programs.rclone.remotes = lib.mkIf (builtins.elem "koofr" hmArgs.config.services.rclone.remotes) {
        koofr = {
          config = {
            type = "koofr";
            endpoint = "https://app.koofr.net";
            user = config.flake.meta.users.aaccardo.email;
          };

          secrets = {
            password = osConfig.services.onepassword-secrets.secretPaths.koofrPassword;
          };
        };
      };
    };
}
