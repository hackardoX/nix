{ config, ... }: {
  flake.modules.homeManager.base =
    hmArgs@{ osConfig, ... }:
    {
      programs.rclone = {
        remotes.koofr = {
          config = {
            type = "koofr";
            endpoint = "https://app.koofr.net";
            user = config.flake.meta.users.${osConfig.system.primaryUser}.email;
          };

          secrets = {
            password = hmArgs.config.programs.onepassword-secrets.secretPaths.koofrPassword;
          };
        };
      };

      programs.onepassword-secrets.secrets.koofrPassword = {
        path = ".secrets/rclone/koofr_password";
        reference = "op://Homelab/Koofr rclone/password";
      };
    };
}
