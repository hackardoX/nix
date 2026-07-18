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
      boot.initrd = {
        enable = true;
        supportedFilesystems = [ "btrfs" ];
        postResumeCommands = lib.mkAfter ''
          mkdir -p /mnt
          mount -o subvol=/ ${config.boot.initrd.impermanence.btrfsDevice} /mnt

          # Safety: verify the blank snapshot exists before destroying anything
          if [[ ! -e /mnt/${config.boot.initrd.impermanence.blankSubvolume} ]]; then
            echo "ERROR: blank snapshot ${config.boot.initrd.impermanence.blankSubvolume} not found!" >&2
            umount /mnt
            exit 1
          fi

          delete_subvolume_recursively() {
            IFS=$'\n'
            # CRITICAL SAFETY: only delete if it's actually a btrfs subvolume (inode=256).
            # If a regular directory is passed, 'btrfs subvolume list -o' enumerates ALL
            # subvolumes on the filesystem, which would wipe the entire drive.
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
          "/var/lib/iwd"
          "/var/lib/opnix"
        ];
        files = [
          "/etc/machine-id"
          "/etc/opnix-token"
          "/etc/ssh/ssh_host_ecdsa_key"
          "/etc/ssh/ssh_host_ecdsa_key.pub"
          "/etc/ssh/ssh_host_ed25519_key"
          "/etc/ssh/ssh_host_ed25519_key.pub"
          "/etc/ssh/ssh_host_rsa_key"
          "/etc/ssh/ssh_host_rsa_key.pub"
          "/etc/secrets/initrd/ssh_host_ed25519_key"
          "/etc/secrets/initrd/ssh_host_ed25519_key.pub"
        ];
      };

      security.sudo.extraConfig = ''
        Defaults lecture = never
      '';
    };
  };

  flake.modules.homeManager.impermanence = { ... }: {
    imports = [ inputs.impermanence.homeManagerModules.default ];
  };
}
