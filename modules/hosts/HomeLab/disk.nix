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
              iBootSystemContainer = {
                label = "iBootSystemContainer";
                priority = 1;
                type = "AF0B";
                uuid = "139e5dc2-7c27-4070-ac5d-c6582bc6a780";
              };
              Container = {
                label = "Container";
                priority = 2;
                type = "AF0A";
                uuid = "5d2cd669-430d-4151-afa4-4e8afe3a497d";
              };
              AsahiStub = {
                priority = 3;
                type = "AF0A";
                uuid = "a9decce4-8a8d-4647-887c-8e1c19aaa9dc";
              };
              ESP = {
                priority = 4;
                type = "EF00";
                uuid = "e862caa4-cb82-4d97-94ce-c9e77a74ef83";
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
                priority = 6;
                type = "AF0C";
                uuid = "60c3b87f-981b-448f-a616-e0675bce34c8";
              };
              luks = {
                priority = 5;
                size = "100%";
                content = {
                  type = "luks";
                  name = "crypted";
                  keyFile = "/tmp/secret.key";
                  passwordFile = "/tmp/secret.key"; # Interactive password entry
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
  };
}
