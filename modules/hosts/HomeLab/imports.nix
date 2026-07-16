{ config, ... }:
{
  configurations.nixos.HomeLab.module = {
    imports = with config.flake.modules.nixos; [
      base
      hal
      # podman
      # hardening
      homelab
    ];
  };
}
