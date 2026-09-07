{
  config,
  ...
}:
{
  flake.modules.homeManager.file-sync = hmArgs: {
    imports = [ config.flake.modules.homeManager.rclone-sync ];

    sops.secrets = {
      "rclone-sync/docs/password" = {
        sopsFile = ../../secrets/shared/secrets.yaml;
        path = "${hmArgs.config.home.homeDirectory}/.secrets/rclone-sync/Documents/password";
      };
      "rclone-sync/docs/salt" = {
        sopsFile = ../../secrets/shared/secrets.yaml;
        path = "${hmArgs.config.home.homeDirectory}/.secrets/rclone-sync/Documents/salt";
      };
    };

    services.rclone-sync.jobs = {
      docs-koofr = {
        localPath = "${hmArgs.config.home.homeDirectory}/Private Docs";
        destination = "Private Docs";
        providers = [
          "koofr"
        ];
        encrypted = true;
        salt = true;
        passwordFile = hmArgs.config.sops.secrets."rclone-sync/docs/password".path;
        saltFile = hmArgs.config.sops.secrets."rclone-sync/docs/salt".path;
        schedule = "minutely";
      };
      docs-gdrive = {
        localPath = "${hmArgs.config.home.homeDirectory}/Private Docs";
        destination = "Private Docs";
        providers = [
          "gdrive"
        ];
        schedule = "minutely";
      };
    };
  };
}
