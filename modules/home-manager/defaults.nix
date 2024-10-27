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
    };

    "com.apple.driver.AppleBluetoothMultitouch.trackpad" = {
      TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
      TrackpadTwoFingerDoubleTapGesture = 1;
      TrackpadFourFingerPinchGesture = 2;
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
  };

  currentHostDefaults = {
    "com.apple.controlcenter".BatteryShowPercentage = true;
  };
}
