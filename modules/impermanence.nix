{ lib, inputs, ... }:
{
  flake.modules.nixos.impermanence = { config, ... }: {
    imports = [ inputs.impermanence.nixosModules.default ];

    options.boot.initrd.impermanence = {
      enable = lib.mkEnableOption "btrfs root subvolume rollback on every boot";
      btrfsDevice = lib.mkOption {
        type = lib.types.str;
        description = "Decrypted btrfs device to mount for rollback (e.g. /dev/mapper/crypted)";
      };
      rootSubvolume = lib.mkOption {
        type = lib.types.str;
        default = "root";
        description = "Name of the root subvolume to roll back";
      };
      blankSubvolume = lib.mkOption {
        type = lib.types.str;
        default = "root-blank";
        description = "Name of the blank snapshot subvolume to restore from";
      };
    };

    config = lib.mkIf config.boot.initrd.impermanence.enable {
      # Required for systemd initrd services to function
      boot.initrd.systemd.enable = true;

      # Ensure btrfs tools are available in initrd
      boot.initrd.supportedFilesystems = [ "btrfs" ];

      # Rollback root to blank snapshot before mounting /
      boot.initrd.systemd.services.rollback = {
        description = "Rollback BTRFS root subvolume to a pristine state";
        wantedBy = [ "initrd.target" ];
        before = [ "sysroot.mount" ];
        unitConfig.DefaultDependencies = "no";
        serviceConfig.Type = "oneshot";

        after = [
          "systemd-cryptsetup@crypted.service"
          "local-fs-pre.target"
        ];

        script = ''
          mkdir -p /mnt
          mount -o subvol=/ ${config.boot.initrd.impermanence.btrfsDevice} /mnt

          if [[ ! -e /mnt/${config.boot.initrd.impermanence.blankSubvolume} ]]; then
            echo "ERROR: blank snapshot ${config.boot.initrd.impermanence.blankSubvolume} not found!" >&2
            umount /mnt
            exit 1
          fi

          delete_subvolume_recursively() {
            IFS=$'\n'
            if [ $(stat -c %i "$1") -ne 256 ]; then return; fi
            for i in $(btrfs subvolume list -o "$1" | cut -f9- -d' '); do
              delete_subvolume_recursively "/mnt/$i"
            done
            echo "deleting subvolume: $1"
            btrfs subvolume delete "$1"
          }

          if [[ -e /mnt/${config.boot.initrd.impermanence.rootSubvolume} ]]; then
            delete_subvolume_recursively /mnt/${config.boot.initrd.impermanence.rootSubvolume}
          fi

          echo "restoring blank /${config.boot.initrd.impermanence.rootSubvolume} subvolume..."
          btrfs subvolume snapshot /mnt/${config.boot.initrd.impermanence.blankSubvolume} /mnt/${config.boot.initrd.impermanence.rootSubvolume}

          umount /mnt
        '';
      };

      fileSystems."/persist".neededForBoot = true;

      environment.persistence."/persist" = {
        directories = [
          "/etc/nixos"
          "/etc/ssh"
          "/etc/secrets/initrd"
          "/var/lib/iwd"
          "/var/lib/opnix"
        ];
        files = [
          "/etc/machine-id"
          "/etc/opnix-token"
        ];
      };

      security.sudo.extraConfig = ''
        Defaults lecture = never
      '';
    };
  };
}
