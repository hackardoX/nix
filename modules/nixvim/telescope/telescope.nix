{
  flake.modules.nixvim.dev.plugins = {
    telescope = {
      enable = true;
      settings.defaults.layout_config = {
        horizontal.preview_width = 0.7;
        cursor.preview_width = 0.7;
        bottom_pane.preview_width = 0.7;
        vertical.preview_height = 0.7;
      };
    };
    web-devicons.enable = true;
  };
}
