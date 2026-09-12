{
  flake.modules.nixvim.dev.plugins = {
    telescope = {
      enable = true;
      settings.defaults = {
        layout_config = {
          preview_width = 0.7;
        };
      };
    };
    web-devicons.enable = true;
  };
}
