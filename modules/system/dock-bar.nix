{
  lib,
  ...
}:
{
  flake.modules.darwin.base =
    {
      config,
      pkgs,
      ...
    }:
    {
      system.defaults = {
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

          persistent-apps = [
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
          ++ lib.optionals (config.programs.spicetify.enable or false) [
            "${config.programs.spicetify.spicedSpotify}/Applications/Spotify.app"
            {
              spacer = {
                small = true;
              };
            }
          ]
          ++ [
            "${pkgs.ghostty-bin}/Applications/Ghostty.app"
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
      };
    };
}
