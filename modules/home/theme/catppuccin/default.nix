{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib)
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;

  cfg = config.${namespace}.theme.catppuccin;
in
{
  options.${namespace}.theme.catppuccin = {
    enable = mkEnableOption "catppuccin theme for applications";

    accent = mkOption {
      type = types.enum [
        "rosewater"
        "flamingo"
        "pink"
        "mauve"
        "red"
        "maroon"
        "peach"
        "yellow"
        "green"
        "teal"
        "sky"
        "sapphire"
        "blue"
        "lavender"
      ];
      default = "blue";
      description = ''
        An optional theme accent.
      '';
    };

    flavor = mkOption {
      type = types.enum [
        "latte"
        "frappe"
        "macchiato"
        "mocha"
      ];
      default = "macchiato";
      description = ''
        An optional theme flavor.
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.catppuccin.override {
        inherit (cfg) accent;
        variant = cfg.flavor;
      };
    };
  };

  config = mkIf cfg.enable {
    catppuccin = {
      inherit (cfg) accent flavor;
      enable = mkDefault true;
    };

    home = {
      file = mkMerge [
        (
          let
            warpPkg = pkgs.fetchFromGitHub {
              owner = "catppuccin";
              repo = "warp";
              rev = "11295fa7aed669ca26f81ff44084059952a2b528";
              hash = "sha256-ym5hwEBtLlFe+DqMrXR3E4L2wghew2mf9IY/1aynvAI=";
            };

            warpStyle = "${warpPkg.outPath}/themes/catppuccin_${cfg.flavor}.yml";
          in
          mkIf config.${config.${namespace}.user.name}.programs.terminal.emulators.warp.enable {
            ".warp/themes/catppuccin_${cfg.flavor}.yaml".source = warpStyle;
            ".local/share/warp-terminal/themes/catppuccin_${cfg.flavor}.yaml".source = warpStyle;
          }
        )
      ];
    };
  };
}
