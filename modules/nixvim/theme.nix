{
  flake.modules.nixvim.dev =
    { homeConfig, ... }:
    {
      colorschemes.catppuccin = {
        inherit (homeConfig.catppuccin) enable;
        settings.flavour = homeConfig.catppuccin.flavor;
      };
    };
}
