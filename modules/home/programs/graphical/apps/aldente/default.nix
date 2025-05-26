{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.programs.graphical.apps.aldente;
in
{
  options.${namespace}.programs.graphical.apps.aldente = {
    enable = lib.mkEnableOption "aldente";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.aldente
    ];

    targets.darwin.defaults = {
      "com.apphousekitchen.aldente-pro" = {
        LaunchAtLogin__hasMigrated = 1;
        SUEnableAutomaticChecks = 1;
        SUHasLaunchedBefore = 1;
        chargeVal = 80;
        checkForUpdates = 1;
        launchAtLogin = 1;
        showDockIcon = 0;
        showGUIonStartup = 1;
      };
    };
  };
}
