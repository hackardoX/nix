{
  flake.modules.nixvim.dev = {
    plugins.which-key = {
      enable = true;
      settings.icons.group = "";
    };
  };
}
