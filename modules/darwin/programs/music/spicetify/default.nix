{
  config,
  lib,
  pkgs,
  namespace,
  inputs,
  ...
}:
let

  cfg = config.${namespace}.programs.music.spicetify;
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.system};
in
{
  options.${namespace}.programs.music.spicetify = {
    enable = lib.mkEnableOption "spicetify";
  };

  config = lib.mkIf cfg.enable {
    programs.spicetify = {
      enable = true;
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
