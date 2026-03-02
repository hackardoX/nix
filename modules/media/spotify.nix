{ inputs, ... }:
{
  flake.modules.darwin.laptop =
    { pkgs, ... }:
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.system};
    in
    {
      imports = [ inputs.spicetify-nix.darwinModules.spicetify ];
      programs.spicetify = {
        enable = true;
        enabledCustomApps = with spicePkgs.apps; [
          historyInSidebar
          marketplace
          ncsVisualizer
          reddit
        ];
        enabledExtensions = with spicePkgs.extensions; [
          hidePodcasts
          shuffle
          betterGenres
        ];
        theme = spicePkgs.themes.catppuccin;
        colorScheme = "macchiato";
      };
    };
}
