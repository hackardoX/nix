{
  configurations.nixos.Hetzner-HomeLab.module = {
    boot.loader.grub.enable = true;
    services.openssh.enable = true;
  };
}
