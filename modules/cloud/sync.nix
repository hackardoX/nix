{
  flake.modules.homeManager.laptop = hmArgs: {
    services.file-mount.mounts = {
      documents = {
        destination = "Private Docs";
        mountPoint = "${hmArgs.config.home.homeDirectory}/Koofr Docs";
        providers = [
          "koofr"
        ];
        encrypted = true;
        salt = true;
      };
    };
  };
}
