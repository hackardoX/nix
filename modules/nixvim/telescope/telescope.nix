{
  flake.modules.nixvim.dev.plugins = {
    telescope = {
      enable = true;
      settings.defaults.layout_config.vertical.width = 0.3;
    };
    web-devicons.enable = true;
  };
}
