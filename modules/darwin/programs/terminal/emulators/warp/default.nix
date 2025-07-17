{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.${namespace}.programs.terminal.emulators.warp;

in
{
  options.${namespace}.programs.terminal.emulators.warp = {
    enable = mkEnableOption "warp";
  };

  config = mkIf cfg.enable {
    homebrew = {
      casks = [
        "warp"
      ];
    };
  };
}
