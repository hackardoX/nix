{
  flake.modules.homeManager.laptop = hmArgs: {
    programs.onepassword-secrets.secrets = {
      documentsPassword = {
        path = ".secrets/file-mount/Documents/password";
        reference = "op://Homelab/File Mount/documents/password";
      };
      documentsSalt = {
        path = ".secrets/file-mount/Documents/salt";
        reference = "op://Homelab/File Mount/documents/salt";
      };
    };

    services.file-mount.mounts = {
      documents = {
        destination = "Private Docs";
        mountPoint = "${hmArgs.config.home.homeDirectory}/Koofr Docs";
        providers = [
          "koofr"
        ];
        encrypted = true;
        salt = true;
        passwordFile = hmArgs.config.programs.onepassword-secrets.secretPaths.documentsPassword;
        saltFile = hmArgs.config.programs.onepassword-secrets.secretPaths.documentsSalt;
      };
    };
  };
}
