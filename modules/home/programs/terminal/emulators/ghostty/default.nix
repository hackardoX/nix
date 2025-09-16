{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.programs.terminal.emulators.ghostty;
in
{
  options.${namespace}.programs.terminal.emulators.ghostty = {
    enable = mkEnableOption "ghostty";
    default = mkBoolOpt false "Whether to set Ghostty as the session EDITOR";
  };

  config = mkIf cfg.enable {
    home = {
      sessionVariables = {
        EDITOR = mkIf cfg.default "ghostty";
      };
    };

    programs.ghostty = {
      enable = true;
      installVimSyntax = true;
      settings = {
        font-size = 14;
        background-blur-radius = 20;
        mouse-hide-while-typing = true;
        window-decoration = true;
        macos-option-as-alt = true;
      };
      package = pkgs.ghostty-bin;
    };
  };
}
