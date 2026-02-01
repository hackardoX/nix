{ config, ... }:
{
  configurations.nixos.Hetzner-HomeLab.module = nixosArgs: {
    boot = {
      loader.grub.enable = true;
      initrd = {
        availableKernelModules = [
          "uhci_hcd" # USB 1.1 Host Controller Interface driver
          "ehci_pci" # USB 2.0 PCI-based Host Controller Interface driver
          "ahci" # Advanced Host Controller Interface for SATA devices
          "virtio_pci" # PCI bus support for virtio
          "virtio_scsi" # SCSI device support for virtualized environments
          "sd_mod" # SCSI disk driver for most storage devices
          "sr_mod" # SCSI CD-ROM/DVD driver
          "virtio_net" # Primary network driver
          "virtio" # Base virtualization support
          "net_failover" # Network failover capability
          "failover" # Base failover functionality
        ];
        kernelModules = [
          "virtio_net" # VirtIO network driver for paravirtualized environments
          "e1000" # Intel Gigabit Ethernet driver for emulated network interfaces
        ];
        network = {
          enable = true;
          ssh = {
            enable = true;
            port = 2222;
            inherit (config.flake.meta.users.hetzner) authorizedKeys;
            hostKeys = [
              nixosArgs.config.services.onepassword-secrets.secretPaths.hetznerHomeLabPrivateKey
              # "/etc/ssh/ssh_host_ed25519_key"
            ];
            shell = "/bin/cryptsetup-askpass";
          };
        };
      };
      kernelParams = [ "ip=dhcp" ];
    };
    services.openssh.enable = true;
  };
}
