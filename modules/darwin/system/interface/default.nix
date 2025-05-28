{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.${namespace}.system.interface;
  hmCfg = config.home-manager.users.${config.${namespace}.user.name};
in
{
  options.${namespace}.system.interface = {
    enable = mkEnableOption "macOS interface";
  };

  config = mkIf cfg.enable {
    ${namespace}.home.file = {
      "Pictures/Screenshots/.keep".text = "";
    };

    system.defaults = {
      CustomSystemPreferences = {
        finder = {
          DisableAllAnimations = true;
          FXEnableExtensionChangeWarning = false;
          QuitMenuItem = true;
          ShowExternalHardDrivesOnDesktop = false;
          ShowHardDrivesOnDesktop = false;
          ShowMountedServersOnDesktop = false;
          ShowPathbar = true;
          ShowRemovableMediaOnDesktop = false;
          _FXSortFoldersFirst = true;
        };

        NSGlobalDomain = {
          WebKitDeveloperExtras = true;
        };
      };

      CustomUserPreferences = {
        "com.apple.SoftwareUpdate" = {
          AutomaticCheckEnabled = true;
          AutomaticDownload = 1;
          CriticalUpdateInstall = 1;
          ScheduleFrequency = 1;
        };
      };

      # dock settings
      dock = {
        # auto show and hide dock
        autohide = false;
        # remove delay for showing dock
        autohide-delay = 0.0;
        # how fast is the dock showing animation
        autohide-time-modifier = 1.0;
        mineffect = "scale";
        minimize-to-application = true;
        mouse-over-hilite-stack = true;
        mru-spaces = false;
        orientation = "bottom";
        show-process-indicators = true;
        show-recents = false;
        showhidden = false;
        static-only = false;
        tilesize = 64;

        # Hot corners
        # Possible values:
        #  0: no-op
        #  2: Mission Control
        #  3: Show application windows
        #  4: Desktop
        #  5: Start screen saver
        #  6: Disable screen saver
        #  7: Dashboard
        # 10: Put display to sleep
        # 11: Launchpad
        # 12: Notification Center
        # 13: Lock Screen
        # 14: Quick Notes
        wvous-tl-corner = 2;
        wvous-tr-corner = 12;
        wvous-bl-corner = 14;
        wvous-br-corner = 4;

        persistent-apps =
          [
            "/Applications/Safari.app"
            {
              spacer = {
                small = true;
              };
            }
            "/System/Applications/Mail.app"
            "/System/Applications/Calendar.app"
            "/System/Applications/Reminders.app"
            "/System/Applications/Messages.app"
            {
              spacer = {
                small = true;
              };
            }
          ]
          ++
            lib.optionals (config.${namespace}.tools.homebrew.enable && hmCfg.${namespace}.suites.music.enable)
              [
                "${pkgs.spotify}/Applications/Spotify.app"
                {
                  spacer = {
                    small = true;
                  };
                }
              ]
          ++ lib.optionals hmCfg.${namespace}.suites.development.enable [
            "${pkgs.vscode}/Applications/Visual Studio Code.app"
            "${pkgs.bruno}/Applications/Bruno.app"
            "/System/Volumes/Data/Applications/Warp.app"
            {
              spacer = {
                small = true;
              };
            }
          ]
          ++ [
            "/System/Applications/System Settings.app"
            {
              spacer = {
                small = true;
              };
            }
          ];
      };

      NSGlobalDomain = {
        "com.apple.sound.beep.feedback" = 0;
        "com.apple.sound.beep.volume" = 0.0;
        AppleShowAllExtensions = true;
        AppleICUForce24HourTime = true;
      };

      screencapture = {
        disable-shadow = true;
        location = "/Users/${config.${namespace}.user.name}/Pictures/Screenshots/";
      };
    };
  };
}
