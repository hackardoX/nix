{
  flake.modules.darwin.base = {
    system.defaults = {
      NSGlobalDomain = {
        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.trackpad.scaling" = 2.5;
      };

      ".GlobalPreferences" = {
        "com.apple.mouse.scaling" = 2.5;
      };

      trackpad = {
        TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
        TrackpadTwoFingerDoubleTapGesture = true;
        TrackpadFourFingerPinchGesture = 2;
        Clicking = true;
        TrackpadThreeFingerDrag = true;
      };
    };
  };
}
