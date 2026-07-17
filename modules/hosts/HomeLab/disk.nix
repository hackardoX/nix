{
  configurations.nixos.HomeLab.module = {
    disko.devices = {
      disk = {
        main = {
          type = "disk";
          device = "/dev/disk/by-id/nvme-APPLE_SSD_AP1024Q_0ba01609449ca217";
          destroy = false;
          content = {
            type = "gpt";
            partitions = {
              # Pre-existing Apple partitions — matched, not allocated (no `size` set).
              # Ordering by priority is safe here since disko locates these on-disk
              # rather than creating them; confirmed working in your setup.
              iBootSystemContainer = {
                label = "iBootSystemContainer";
                priority = 1;
                type = "AF0B";
                uuid = "b99a06e4-ef87-4397-ae4f-7eb14d019240";
              };
              Container = {
                label = "Container";
                priority = 2;
                type = "AF0A";
                uuid = "d10753fd-90b7-4555-88a4-bc4e6c7ac7d5";
              };
              AsahiStub = {
                label = "AsahiStub";
                priority = 3;
                type = "AF0A";
                uuid = "d09fcd13-2f74-4fb2-bc8a-db2b8e6d6676";
              };
              ESP = {
                label = "ESP";
                priority = 4;
                type = "EF00";
                uuid = "2481db01-fc76-4e22-99c8-c184fa675265";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [
                    "fmask=0077"
                    "dmask=0077"
                  ];
                };
              };
              RecoveryOSContainer = {
                label = "RecoveryOSContainer";
                priority = 5;
                type = "AF0C";
                uuid = "9ec06d70-8edf-4a9e-9d5b-e89b10c415a8";
              };
              luks = {
                label = "luks";
                priority = 6;
                size = "100%";
                content = {
                  type = "luks";
                  name = "crypted";
                  passwordFile = "/tmp/secret.key";
                  extraFormatArgs = [ "--pbkdf argon2id" ];
                  content = {
                    type = "btrfs";
                    extraArgs = [ "-f" ];
                    subvolumes =
                      let
                        mountOptions = [
                          "compress=zstd"
                          "noatime"
                          "discard=async"
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
                        "/data" = {
                          mountpoint = "/var/lib/data";
                          mountOptions = [
                            "noatime"
                            "nodatacow"
                            "discard=async"
                          ];
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
  };
}
