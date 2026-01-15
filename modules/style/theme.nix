{
  inputs,
  ...
}:
{
  flake.modules.homeManager.theme = {
    imports = [ inputs.catppuccin.homeModules.catppuccin ];
    catppuccin = {
      enable = true;
      accent = "blue";
      flavor = "macchiato";
    };
  };
}
