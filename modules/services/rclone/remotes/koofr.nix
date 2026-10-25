{
  config,
  inputs,
  lib,
  ...
}:
let
  email = config.flake.meta.users.hackardo.email;
  polyModule = {
    sops.secrets."rclone/koofr/password" = {
      sopsFile = "${inputs.self}/secrets/shared/secrets.yaml";
    };
  };
in
{
  flake.modules.nixos.rclone = polyModule;
  flake.modules.darwin.rclone = polyModule;
  flake.modules.homeManager.rclone = hmArgs: {
    programs.rclone.remotes = lib.mkIf (builtins.elem "koofr" hmArgs.config.services.rclone.remotes) {
      koofr = {
        config = {
          type = "koofr";
          endpoint = "https://app.koofr.net";
          user = email;
        };

        secrets = {
          password = hmArgs.osConfig.sops.secrets."rclone/koofr/password".path;
        };
      };
    };
  };
}
