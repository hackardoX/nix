{ config, ... }:
{
  configurations.nixos.HomeLab.module = {
    imports = with config.flake.modules.nixos; [
      base
      hal
      # hardening
      deploy
      homelab
      impermanence
      homelab-ingress
      root
      ssh
      sudo
    ];

    home-manager.users.${config.flake.meta.users.hal.name} = config.flake.modules.homeManager.hal;
  };
}
