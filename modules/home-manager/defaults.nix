let
  keyboard = {
    id = 15000;
    name = "USInternational-PC";
  };
in
{
  defaults = {
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      ApplePressAndHoldEnabled = false;
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      com.apple.mouse.tapBehavior = 1;
      com.apple.sound.beep.volume = 0.0;
      com.apple.sound.beep.feedback = 0;
      com.apple.trackpad.scaling = 2.0;
      AppleICUForce24HourTime = true;
    };

    com.apple.AppleMultitouchTrackpad = {
      TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
      TrackpadTwoFingerDoubleTapGesture = 1;
      TrackpadFourFingerPinchGesture = 2;
      Clicking = true;
      TrackpadThreeFingerDrag = true;
    };

    com.apple.driver.AppleBluetoothMultitouch.trackpad = {
      TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
      TrackpadTwoFingerDoubleTapGesture = 1;
      TrackpadFourFingerPinchGesture = 2;
      Clicking = true;
      TrackpadThreeFingerDrag = true;
    };

    com.apple.dock = {
      autohide = false;
      tilesize = 64;
      showAppExposeGestureEnabled = true;
    };

    dev.warp.Warp-Stable = {
      AliasExpansionBannerSeen = "true";
      AliasExpansionEnabled = "true";
      Notifications = "{\"mode\":\"Enabled\",\"is_long_running_enabled\":true,\"long_running_threshold\":{\"secs\":30,\"nanos\":0},\"is_password_prompt_enabled\":true}";
      TelemetryEnabled = "false";
      AutocompleteSymbols = "false";
    };

    com.apphousekitchen.aldente-pro = {
      LaunchAtLogin__hasMigrated = 1;
      SUEnableAutomaticChecks = 1;
      SUHasLaunchedBefore = 1;
      chargeVal = 75;
      checkForUpdates = 1;
      launchAtLogin = 1;
      showDockIcon = 0;
      showGUIonStartup = 1;
    };

    com.apple.menuextra.clock = {
      Show24Hour = true;
      ShowDayOfWeek = true;
      ShowSeconds = false;
      ShowTime = true;
      ShowDate = 0;
    };

    com.apple.HIToolbox = {
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

    com.apple.Safari = {
      IncludeDevelopMenu = true;
    };
  };

  currentHostDefaults = {
    com.apple.controlcenter.BatteryShowPercentage = true;
  };
}
