{
  flake.modules.homeManager.laptop = hmArgs: {
    services.file-sync.jobs = {
      documents = {
        source = "${hmArgs.config.home.homeDirectory}/koofr";
        destination = "Private Docs";
        providers = [
          "koofr"
        ];
        encrypted = true;
      };
    };
  };
}
