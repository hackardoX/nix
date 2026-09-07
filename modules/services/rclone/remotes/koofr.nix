{ config, lib, ... }:
let
  email = config.flake.lib.fromBase64 "aGFja2FyZG9AZ21haWwuY29t";
in
{
  flake.modules.nixos.rclone = { };
  flake.modules.darwin.rclone = { };
  flake.modules.homeManager.rclone = hmArgs: {
    sops.secrets."rclone/koofr/password" = {
      sopsFile = ../../../../secrets/shared/secrets.yaml;
    };

    programs.rclone.remotes = lib.mkIf (builtins.elem "koofr" hmArgs.config.services.rclone.remotes) {
      koofr = {
        config = {
          type = "koofr";
          endpoint = "https://app.koofr.net";
          user = email;
        };

        secrets = {
          password = hmArgs.config.sops.secrets."rclone/koofr/password".path;
        };
      };
    };
  };
}
