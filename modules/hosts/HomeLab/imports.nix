{ config, ... }:
{
  configurations.nixos.HomeLab.module =
    { modulesPath, ... }:
    {
      imports = with config.flake.modules.nixos; [
        base
        hal
        # podman
        hardening
        homelab
      ];
    };
}
