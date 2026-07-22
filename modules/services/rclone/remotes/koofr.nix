{ config, ... }: {
  flake.modules.homeManager.base =
    hmArgs@{ pkgs, ... }:
    {
      programs.rclone = {
        remotes.koofr = {
          config = {
            type = "koofr";
            endpoint = "https://app.koofr.net";
            user = config.flake.meta.users.aaccardo.email;
          };

          secrets = {
            password = hmArgs.config.programs.onepassword-secrets.secretPaths.koofrPassword;
          };
        };
      };

      programs.onepassword-secrets.secrets.koofrPassword = {
        path = ".secrets/rclone/koofr_password";
        reference = "op://Homelab/Rclone remotes/Koofr/password";
        owner = hmArgs.config.home.username;
        group = if pkgs.stdenv.isDarwin then "staff" else "wheel";
      };
    };
}
