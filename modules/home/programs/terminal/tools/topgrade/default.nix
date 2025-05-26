{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.programs.terminal.tools.topgrade;
in
{
  options.${namespace}.programs.terminal.tools.topgrade = {
    enable = lib.mkEnableOption "topgrade";
  };

  config = mkIf cfg.enable {
    programs.topgrade = {
      enable = true;

      settings = {
        misc = {
          no_retry = true;
          display_time = true;
          skip_notify = true;
        };
        git = {
          repos = [
            "~/Github/*/"
          ];
        };
      };
    };
  };
}
