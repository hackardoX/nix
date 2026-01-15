{ lib, ... }:
{
  flake.modules.homeManager.laptop =
    { pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
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
