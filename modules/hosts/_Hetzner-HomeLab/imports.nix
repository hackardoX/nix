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
        deploy
        homelab
        impermanence
        # TODO: add root sops secret
        # root
        ssh
        sudo
      ];

      sops.defaultSopsFile = ../../../secrets/homelab/services.yaml;

      home-manager.users.${config.flake.meta.users.hetzner.name} =
        config.flake.modules.homeManager.hetzner;
    };
}
