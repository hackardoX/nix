{
  configurations.nixos.HomeLab.module = {
    disko.devices = {
      disk = {
        main = {
          type = "disk";
          device = "/dev/disk/by-id/nvme-APPLE_SSD_XXXXXXXXXXXXXXXX"; # TODO: update with actual disk ID
          destroy = false;
          content = {
            type = "gpt";
            partitions = {
              iBootSystemContainer = {
                label = "iBootSystemContainer";
                priority = 1;
                type = "AF0B";
                uuid = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"; # TODO: update with actual UUID
              };
              Container = {
                label = "Container";
                priority = 2;
                type = "AF0A";
                uuid = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"; # TODO: update with actual UUID
              };
              AsahiStub = {
                priority = 3;
                type = "AF0A";
                uuid = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"; # TODO: update with actual UUID
              };
              ESP = {
                priority = 4;
                type = "EF00";
                uuid = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"; # TODO: update with actual UUID
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [
                    "fmask=0022"
                    "dmask=0022"
                  ];
                };
              };
              root = {
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
              RecoveryOSContainer = {
                label = "RecoveryOSContainer";
                priority = 5;
                type = "AF0C";
                uuid = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"; # TODO: update with actual UUID
              };
            };
          };
        };
      };
    };

    # Required for Asahi Linux EFI boot
    boot.loader.efi.canTouchEfiVariables = false;
    boot.loader.systemd-boot.enable = true;
  };
}
