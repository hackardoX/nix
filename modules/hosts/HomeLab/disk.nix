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
              RecoveryOSContainer = {
                label = "RecoveryOSContainer";
                priority = 5;
                type = "AF0C";
                uuid = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"; # TODO: update with actual UUID
              };
              luks = {
                size = "100%";
                content = {
                  type = "luks";
                  name = "crypted";
                  # passwordFile = "/tmp/secret.key"; # Interactive password entry
                  extraFormatArgs = [ "--pbkdf argon2id" ];
                  content = {
                    type = "btrfs";
                    extraArgs = [ "-f" ];
                    subvolumes =
                      let
                        mountOptions = [
                          "compress=zstd"
                          "noatime"
                        ];
                      in
                      {
                        "/root" = {
                          mountpoint = "/";
                          inherit mountOptions;
                        };
                        "/home" = {
                          mountpoint = "/home";
                          inherit mountOptions;
                        };
                        "/nix" = {
                          mountpoint = "/nix";
                          inherit mountOptions;
                        };
                        "/swap" = {
                          mountpoint = "/swap";
                          swap.swapfile.size = "16G";
                        };
                      };
                  };
                };
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
