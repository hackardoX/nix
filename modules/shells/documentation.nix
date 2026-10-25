{
  flake.modules.homeManager.cli-docs.programs = {
    tealdeer = {
      enable = true;
      settings.display.use_pager = true;
    };
    info.enable = true;
  };
}
