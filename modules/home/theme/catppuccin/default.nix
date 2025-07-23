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

      vscode.profiles = builtins.listToAttrs (
        map (name: {
          inherit name;
          value = { };
        }) config.${namespace}.programs.graphical.editors.vscode.profiles
      );
    };

    home = {
      file = lib.mkMerge [
        (
          let
            warpThemePkg = pkgs.fetchFromGitHub {
              owner = "catppuccin";
              repo = "warp";
              rev = "b6891cc339b3a1bb70a5c3063add4bdbd0455603";
              hash = "sha256-ypzSeSWT2XfdjfdeE/lLdiRgRmxewAqiWhGp6jjF7hE=";
            };

            themes = [
              "catppuccin_macchiato"
              "catppuccin_mocha"
              "catppuccin_frappe"
              "catppuccin_latte"
            ];

            makeThemeEntry = pathPrefix: theme: {
              name = "${pathPrefix}/${theme}.yaml";
              value.source = "${warpThemePkg.outPath}/themes/${theme}.yml";
            };

            warpThemes = builtins.listToAttrs (
              builtins.concatLists (
                map (theme: [
                  (makeThemeEntry ".warp/themes" theme)
                  (makeThemeEntry ".local/share/warp-terminal/themes" theme)
                ]) themes
              )
            );
          in

          lib.mkIf config.${config.${namespace}.user.name}.programs.terminal.emulators.warp.enable warpThemes
        )
      ];
    };
  };
}
