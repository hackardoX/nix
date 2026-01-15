{ config, ... }:
{
  configurations.nixos.Hetzner-HomeLab.module = nixosArgs: {
    boot = {
      loader.grub.enable = true;
      initrd = {
        availableKernelModules = [
          "ahci"
          "xhci_pci"
          "virtio_pci"
          "virtio_scsi"
          "sd_mod"
          "sr_mod"
        ];
        kernelModules = [ ];
        network = {
          enable = true;
          ssh = {
            enable = true;
            inherit (config.flake.meta.users.hetzner) authorizedKeys;
            hostKeys = [
              nixosArgs.config.services.onepassword-secrets.secretPaths.hetznerHostPrivateKey
            ];
            shell = "/bin/cryptsetup-askpass";
          };
        };
      };
      kernelModules = [ ];
      extraModulePackages = [ ];
    };
    services.openssh.enable = true;
  };
}
