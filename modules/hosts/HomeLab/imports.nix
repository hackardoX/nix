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
      ingress
      root
      security
      ssh
    ];

    home-manager.users.${config.flake.meta.users.hal.name} = config.flake.modules.homeManager.hal;
  };
}
