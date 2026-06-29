{
  flake.modules.homeManager.laptop = hmArgs: {
    programs.onepassword-secrets.secrets = {
      docsPassword = {
        path = ".secrets/rclone-sync/Documents/password";
        reference = "op://Homelab/Cloud Encryption/Docs/password";
      };
      docsSalt = {
        path = ".secrets/rclone-sync/Documents/salt";
        reference = "op://Homelab/Cloud Encryption/Docs/salt";
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
        passwordFile = hmArgs.config.programs.onepassword-secrets.secretPaths.docsPassword;
        saltFile = hmArgs.config.programs.onepassword-secrets.secretPaths.docsSalt;
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
