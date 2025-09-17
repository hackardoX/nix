{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let

  cfg = config.${namespace}.programs.terminal.tools.pay-respects;
in
{
  options.${namespace}.programs.terminal.tools.pay-respects = {
    enable = lib.mkEnableOption "pay-respects";
  };

  config = lib.mkIf cfg.enable {
    programs.pay-respects = {
      enable = true;
      package = pkgs.pay-respects;
      enableZshIntegration = true;
    };
  };
}
