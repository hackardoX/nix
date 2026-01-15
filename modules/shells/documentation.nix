{
  flake.modules.homeManager.dev.programs = {
    tealdeer = {
      enable = true;
      settings.display.use_pager = true;
    };
    info.enable = true;
  };
}
