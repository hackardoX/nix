{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.${namespace}.system.interface;
in
{
  options.${namespace}.system.interface = {
    enable = mkEnableOption "macOS interface";
  };

  config = mkIf cfg.enable {
    targets.darwin = {
      defaults = {
        "com.apple.dock" = {
          autohide = false;
          tilesize = 64;
          showAppExposeGestureEnabled = true;
          show-recents = false;
          size-immutable = true;
        };

        "com.apple.finder" = {
          ShowPathbar = 1;
          ShowSidebar = 1;
          ShowStatusBar = 1;
          FXDefaultSearchScope = "SCcf";
        };

        "com.apple.Safari" = {
          IncludeDevelopMenu = true;
        };

        "com.apple.menuextra.clock" = {
          Show24Hour = true;
          ShowDayOfWeek = true;
          ShowSeconds = false;
          ShowTime = true;
          ShowDate = 0;
        };

        currentHostDefaults = {
          com.apple.controlcenter.BatteryShowPercentage = true;
        };
      };
    };
  };
}
