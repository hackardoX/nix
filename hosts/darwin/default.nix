{ config, pkgs, ... }:

let user = "aaccardo"; in

{
  imports = [
    ../../modules/darwin/home-manager.nix
    ../../modules/shared
  ];

  services.nix-daemon.enable = true;

  nix = {
    package = pkgs.nix;
    settings = {
      trusted-users = [
        "@admin"
        "${user}"
      ];
      substituters = [
        "https://nix-community.cachix.org"
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
    };

    gc = {
      user = "root";
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 2;
        Minute = 0;
      };
      options = "--delete-older-than 30d";
    };

    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # system.checks.verifyNixPath = false;

  environment.systemPackages = builtins.import ../../modules/shared/packages.nix { inherit pkgs; };

  system = {
    stateVersion = 4;

    defaults = {
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        ApplePressAndHoldEnabled = false;

        KeyRepeat = 2; # Values: 120, 90, 60, 30, 12, 6, 2
        InitialKeyRepeat = 15; # Values: 120, 94, 68, 35, 25, 15

        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.sound.beep.volume" = 0.0;
        "com.apple.sound.beep.feedback" = 0;
	
        "com.apple.trackpad.scaling" = 2.0;
      };

      dock = {
        autohide = false;
        show-recents = false;
        launchanim = true;
        orientation = "bottom";
        tilesize = 64;
      };

      finder = {
        _FXShowPosixPathInTitle = false;
      };

      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = true;
      };

      ".GlobalPreferences" = {
        "com.apple.mouse.scaling" = 2.0;
      };

      CustomUserPreferences = {
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
            showAppExposeGestureEnabled = true;
        };

        "~/Library/Preferences/ByHost/com.apple.controlcenter.plist" = {
          BatteryShowPercentage = 1;
        };
      };
    };
  };
}
