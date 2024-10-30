{
  defaults = {
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      ApplePressAndHoldEnabled = false;
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      "com.apple.mouse.tapBehavior" = 1;
      "com.apple.sound.beep.volume" = 0.0;
      "com.apple.sound.beep.feedback" = 0;
      "com.apple.trackpad.scaling" = 2.0;
    };

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

    "com.apple.dock" = {
      autohide = false;
      tilesize = 64;
      showAppExposeGestureEnabled = true;
    };

    "dev.warp.Warp-Stable" = {
      AliasExpansionBannerSeen = true;
      AliasExpansionEnabled = true;
      TelemetryEnabled = false;
    };

    "com.apphousekitchen.aldente-pro" = {
      LaunchAtLogin__hasMigrated = 1;
      SUEnableAutomaticChecks = 1;
      SUHasLaunchedBefore = 1;
      chargeVal = 70;
      checkForUpdates = 1;
      launchAtLogin = 1;
      showDockIcon = 0;
      showGUIonStartup = 1;
    };

    "com.apple.Safari" = {
      IncludeDevelopMenu = true;
    };
  };

  currentHostDefaults = {
    "com.apple.controlcenter".BatteryShowPercentage = true;
  };
}
