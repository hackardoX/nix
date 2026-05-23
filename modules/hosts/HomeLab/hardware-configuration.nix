{
  config,
  ...
}:
{
  configurations.nixos.HomeLab.module =
    { modulesPath, ... }@nixosArgs:
    {
      imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

      boot = {
        loader.systemd-boot.enable = true;
        initrd = {
          availableKernelModules = [
            "nvme" # NVMe SSD driver
            "usb_storage" # USB storage for installer/key files
            "xhci_pci" # USB 3.0 controller
            "usbhid" # USB HID devices
            "hid_apple" # Apple keyboard/mouse support
          ];
          kernelModules = [
            "brcmfmac" # Broadcom WiFi (Apple Silicon)
          ];
          luks.devices."crypted".device = "/dev/disk/by-uuid/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"; # TODO: update with actual LUKS UUID
          network = {
            enable = true;
            ssh = {
              enable = true;
              port = 2222;
              inherit (config.flake.meta.users.hal) authorizedKeys;
              hostKeys = [
                nixosArgs.config.services.onepassword-secrets.secretPaths.homeLabPrivateKey
              ];
              shell = "/bin/cryptsetup-askpass";
            };
          };
        };
        kernelParams = [ "ip=dhcp" ];
      };
      services.openssh.enable = true;

      fileSystems."/" = {
        device = "/dev/mapper/crypted";
        fsType = "btrfs";
        options = [
          "subvol=root"
          "compress=zstd"
          "noatime"
        ];
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"; # TODO: update with ESP UUID
        fsType = "vfat";
        options = [
          "fmask=0022"
          "dmask=0022"
        ];
      };

      fileSystems."/home" = {
        device = "/dev/mapper/crypted";
        fsType = "btrfs";
        options = [
          "subvol=home"
          "compress=zstd"
          "noatime"
        ];
      };

      fileSystems."/nix" = {
        device = "/dev/mapper/crypted";
        fsType = "btrfs";
        options = [
          "subvol=nix"
          "compress=zstd"
          "noatime"
        ];
      };

      fileSystems."/swap" = {
        device = "/dev/mapper/crypted";
        fsType = "btrfs";
        options = [ "subvol=swap" ];
      };

      swapDevices = [ { device = "/swap/swapfile"; } ];
    };
}
