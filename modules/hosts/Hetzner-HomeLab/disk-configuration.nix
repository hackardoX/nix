{
  configurations.nixos.Hetzner-HomeLab.module = {
    disko.devices = {
      disk = {
        main = {
          type = "disk";
          device = "/dev/sda";
          content = {
            type = "gpt";
            partitions = {
              boot = {
                name = "boot";
                size = "1M";
                type = "EF02";
              };
              ESP = {
                name = "esp";
                size = "512M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                };
              };
              luks = {
                size = "100%";
                content = {
                  type = "luks";
                  name = "nixos";
                  passwordFile = "/tmp/disk.key";
                  settings = {
                    allowDiscards = true;
                    bypassWorkqueues = true;
                  };
                  content = {
                    type = "btrfs";
                    extraArgs = [
                      "-L"
                      "nixos"
                      "-f"
                    ];
                    subvolumes =
                      let
                        btrfsopt = [
                          "compress=zstd"
                          "noatime"
                          "ssd"
                        ];
                      in
                      {
                        "@root" = {
                          mountpoint = "/";
                          mountOptions = btrfsopt;
                        };
                        "@home" = {
                          mountpoint = "/home";
                          mountOptions = btrfsopt;
                        };
                        "@nix" = {
                          mountpoint = "/nix";
                          mountOptions = btrfsopt;
                        };
                        "@data" = {
                          mountpoint = "/data";
                          mountOptions = btrfsopt;
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
