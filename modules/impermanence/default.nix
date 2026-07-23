{ lib, inputs, ... }:
{
  flake.modules.nixos.impermanence =
    { config, ... }:
    let
      inherit (config.boot.initrd.impermanence) persistPath;
    in
    {
      imports = [ inputs.impermanence.nixosModules.default ];

      options.boot.initrd.impermanence = {
        enable = lib.mkEnableOption "btrfs root subvolume rollback on every boot";
        persistPath = lib.mkOption {
          type = lib.types.str;
          default = null;
          description = ''
            Path to the persistent storage mountpoint (e.g. /persist).
            The mountpoint is marked neededForBoot so impermanence
            activation runs at the right time.
          '';
        };
        btrfsDevice = lib.mkOption {
          type = lib.types.str;
          description = "Decrypted btrfs device to mount for rollback (e.g. /dev/mapper/crypted).";
        };
        rootSubvolume = lib.mkOption {
          type = lib.types.str;
          default = "root";
          description = "Name of the root subvolume to roll back.";
        };
        blankSubvolume = lib.mkOption {
          type = lib.types.str;
          default = "root-blank";
          description = "Name of the blank snapshot subvolume to restore from.";
        };
        hideMounts = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Hide the bind mounts from showing up as mounted drives in the file manager.";
        };
        persist = {
          directories = lib.mkOption {
            type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
            default = [ ];
            description = ''
              Directories requested for persistence. Safe to set on any host —
              only consumed if modules/impermanence/default.nix is also imported.
            '';
          };
          files = lib.mkOption {
            type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
            default = [ ];
          };
        };
      };

      config = lib.mkIf config.boot.initrd.impermanence.enable {
        fileSystems.${persistPath}.neededForBoot = true;

        # Avoid sudo lectures after rollback
        security.sudo.extraConfig = ''
          Defaults lecture = never
        '';

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

          environment.persistence.${persistPath} = {
            directories = config.boot.initrd.impermanence.persist.directories;
            files = config.boot.initrd.impermanence.persist.files;
          };
        };
      };
    };
}
