{ config, ... }:
{
  configurations.nixos.Hetzner-HomeLab.module =
    { modulesPath, ... }:
    {
      imports = with config.flake.modules.nixos; [
        (modulesPath + "/installer/scan/not-detected.nix")
        (modulesPath + "/profiles/qemu-guest.nix")
        base
        hardening
        hetzner
        homelab
      ];
    };
}
