{ lib, ... }:
{
  flake.modules.homeManager.base =
    { pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      targets.darwin = {
        defaults = {
          NSGlobalDomain = {
            "com.apple.mouse.tapBehavior" = 1;
            "com.apple.trackpad.scaling" = 2.5;
          };

          ".GlobalPreferences" = {
            "com.apple.mouse.scaling" = 2.5;
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
        };
      };
    };
}
