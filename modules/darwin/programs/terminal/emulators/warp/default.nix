{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkBoolOpt mkEnableOption mkIf;

  cfg = config.${namespace}.programs.terminal.emulators.warp;

in
{
  options.${namespace}.programs.terminal.emulators.warp = {
    enable = mkEnableOption "warp";
    default = mkBoolOpt true "Whether to set Warp as the session EDITOR";
  };

  config = mkIf cfg.enable {
    homebrew = {
      casks = [
        "warp"
      ];
    };
  };
}
