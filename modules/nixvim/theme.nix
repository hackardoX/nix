{
  flake.modules.nixvim.dev =
    {
      homeConfig ? { },
      lib,
      ...
    }:
    lib.mkIf (homeConfig ? catppuccin) {
      colorschemes.catppuccin = {
        inherit (homeConfig.catppuccin) enable;
        settings.flavour = homeConfig.catppuccin.flavor;
      };
    };
}
