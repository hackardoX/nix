{
  config,
  inputs,
  lib,
  ...
}:
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
      sops
      ssh
      sudo
    ];

    sops.defaultSopsFile = "${inputs.self}/secrets/homelab/services.yaml";

    # Activation (and so sops-nix, including neededForUsers secrets) runs before
    # the /var/lib/sops bind mount from /persist exists, because only
    # neededForBoot filesystems are mounted before activation. Read the age key
    # from /persist directly, which is mounted in the initrd.
    sops.age.keyFile = lib.mkForce "/persist/var/lib/sops/age-key.txt";

    home-manager.users.${config.flake.meta.users.hal.name} = config.flake.modules.homeManager.hal;
  };

  configurations.nixos.HomeLab-CI.module = {
    imports = [ config.configurations.nixos.HomeLab.module ];
    hardware.asahi.enable = lib.mkForce false;
  };
}
