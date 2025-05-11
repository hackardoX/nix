{
  pkgs,
  lib,
  user,
  ...
}:
{
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = false;
      allowInsecure = false;
      allowUnsupportedSystem = false;
    };
  };

  nix = {
    enable = true;
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
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 2;
        Minute = 0;
      };
      options = "--delete-older-than 30d";
    };

    optimise.automatic = true;

    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  system.stateVersion = 5;

  system.activationScripts.postUserActivation.enable = true;
  system.activationScripts.postUserActivation.text =
    let
      hotkeys = [
        64 # Spotlight
      ];
      disableHotKeyCommands = map (
        key:
        "defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add ${toString key} '
        <dict>
          <key>enabled</key><false/>
          <key>value</key>
          <dict>
            <key>type</key><string>standard</string>
            <key>parameters</key>
            <array>
              <integer>65535</integer>
              <integer>65535</integer>
              <integer>0</integer>
            </array>
          </dict>
        </dict>'"
      ) hotkeys;
    in
    ''
      echo >&2 "configuring hotkeys..."
      ${lib.concatStringsSep "\n" disableHotKeyCommands}
      # credit: https://zameermanji.com/blog/2021/6/8/applying-com-apple-symbolichotkeys-changes-instantaneously/
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

      echo >&2 "creating screenshots folder..."
      mkdir -p /Users/${user}/Pictures/Screenshots
    '';

  time.timeZone = "Europe/Paris";

  users.users.${user} = {
    name = "${user}";
    home = "/Users/${user}";
    isHidden = false;
    shell = pkgs.zsh;
  };
}
