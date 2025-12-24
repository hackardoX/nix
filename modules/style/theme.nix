{
  inputs,
  ...
}:
{
  flake.modules.homeManager.base = {
    imports = [ inputs.catppuccin.homeModules.catppuccin ];
    catppuccin = {
      enable = true;
      accent = "blue";
      flavor = "macchiato";

      # vscode.profiles = builtins.listToAttrs (
      #   map (name: {
      #     inherit name;
      #     value = {
      #       settings = {
      #         syncWithIconPack = false;
      #       };
      #     };
      #   }) config.vscode.profiles
      # );
    };
  };
}
