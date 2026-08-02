{ config, lib, ... }:
{
  configurations.nixos.HomeLab.module = {
    imports = with config.flake.modules.nixos; [
      base
      hal
      # hardening
      deploy
      homelab
      impermanence
      root
      ssh
      sudo
    ];

    home-manager.users.${config.flake.meta.users.hal.name} = config.flake.modules.homeManager.hal;
  };

  configurations.nixos.HomeLab-CI.module = {
    imports = [ config.configurations.nixos.HomeLab.module ];
    hardware.asahi.enable = lib.mkForce false;
  };
}
