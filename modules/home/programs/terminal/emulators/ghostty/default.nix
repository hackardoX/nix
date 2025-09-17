{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.${namespace}.programs.terminal.emulators.ghostty;
in
{
  options.${namespace}.programs.terminal.emulators.ghostty = {
    enable = mkEnableOption "ghostty";
  };

  config = mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      installVimSyntax = true;
      settings = {
        font-size = 14;
        background-blur-radius = 20;
        mouse-hide-while-typing = true;
        window-decoration = true;
        macos-option-as-alt = true;
        keybind = [
          "alt+left=unbind"
          "alt+right=unbind"
        ];
      };
      package = pkgs.ghostty-bin;
    };
  };
}
