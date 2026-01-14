{ config, modulesPath, ... }:
{
  configurations.nixos.Hetzner-HomeLab.module = {
    imports = with config.flake.modules.nixos; [
      (modulesPath + "/installer/scan/not-detected.nix")
      (modulesPath + "/profiles/qemu-guest.nix")
      hetzner
    ];
  };
}
