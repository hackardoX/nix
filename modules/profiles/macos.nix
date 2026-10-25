{ config, ... }:
{
  flake.modules.darwin.macos = {
    imports = with config.flake.modules.darwin; [
      auto-upgrade
      battery
      clock
      dock
      fonts
      keyboard
      menu-bar
      mute-beeps
      rosetta
      safari
      screenshot
      trackpad
    ];
  };
}
