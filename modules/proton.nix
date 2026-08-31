{ config, pkgs, ... }:
{
  flake.modules.darwin.proton = {
    imports = [
      config.flake.modules.darwin.proton-pass
    ];

    homebrew = {
      casks = [
        "proton-drive"
        "proton-meet"
      ];
    };

    environment.systemPackages = with pkgs; [
      proton-vpn
      protonmail-desktop
      protonmail-bridge
      proton-authenticator
    ];
  };
}
