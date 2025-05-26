{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkMerge mkEnableOption;

  cfg = config.${namespace}.system.input;
in
{
  options.${namespace}.system.input = {
    enable = mkEnableOption "macOS input";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      targets.darwin = {
        defaults = {
          "com.apple.AppleMultitouchTrackpad" = {
            TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
            TrackpadTwoFingerDoubleTapGesture = 1;
            TrackpadFourFingerPinchGesture = 2;
            Clicking = true;
            TrackpadThreeFingerDrag = true;
          };

          "com.apple.driver.AppleBluetoothMultitouch.trackpad" = {
            TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
            TrackpadTwoFingerDoubleTapGesture = 1;
            TrackpadFourFingerPinchGesture = 2;
            Clicking = true;
            TrackpadThreeFingerDrag = true;
          };

          "com.apple.HIToolbox" =
            let
              keyboard = {
                id = 15000;
                name = "USInternational-PC";
              };
            in
            {
              AppleCurrentKeyboardLayoutInputSourceID = "com.apple.keylayout.${keyboard.name}";
              AppleInputSourceHistory = [
                {
                  InputSourceKind = "Keyboard Layout";
                  "KeyboardLayout ID" = keyboard.id;
                  "KeyboardLayout Name" = keyboard.name;
                }
              ];
              AppleEnabledInputSources = [
                {
                  InputSourceKind = "Keyboard Layout";
                  "KeyboardLayout ID" = keyboard.id;
                  "KeyboardLayout Name" = keyboard.name;
                }
              ];
              AppleSelectedInputSources = [
                {
                  InputSourceKind = "Keyboard Layout";
                  "KeyboardLayout ID" = keyboard.id;
                  "KeyboardLayout Name" = keyboard.name;
                }
              ];
            };

          NSGlobalDomain = {
            ApplePressAndHoldEnabled = false;
            KeyRepeat = 2;
            InitialKeyRepeat = 15;
            "com.apple.mouse.tapBehavior" = 1;
            "com.apple.trackpad.scaling" = 2.5;
            NSAutomaticCapitalizationEnabled = false;
            NSAutomaticDashSubstitutionEnabled = false;
            NSAutomaticQuoteSubstitutionEnabled = false;
            NSAutomaticPeriodSubstitutionEnabled = false;
            NSAutomaticSpellingCorrectionEnabled = false;
          };

          ".GlobalPreferences" = {
            "com.apple.mouse.scaling" = 2.5;
          };
        };
      };
    }
  ]);
}
