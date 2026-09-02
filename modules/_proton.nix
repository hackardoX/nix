{ config, pkgs, ... }:
let
  polyModule = {
    imports = [
      config.flake.modules.darwin.proton-pass
    ];

    homebrew = {
      casks = [
        "proton-drive"
        "proton-meet"
      ];
    };
  };
in
{
  flake.modules.darwin.proton = polyModule;
  flake.modules.nixos.proton = polyModule;
  flake.modules.homeManager.proton = {
    imports = [
      config.flake.modules.homeManager.proton-pass
    ];

    home.packages = with pkgs; [
      proton-vpn
      protonmail-desktop
      protonmail-bridge
      proton-authenticator
    ];
  };
}
