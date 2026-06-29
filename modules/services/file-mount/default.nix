{
  lib,
  ...
}:
{
  flake.modules.homeManager.base =
    hmArgs:
    let
      cfg = hmArgs.config.services.file-mount;
      rcloneRemotes = hmArgs.config.programs.rclone.remotes or { };

      inherit (hmArgs.config.flake.lib.rclone) mkCryptRemoteName mkRcloneCryptRemote;

      cacheMaxAge = "720h";
      cacheMaxSize = "10G";
      dirCacheTime = "5m";
      pollInterval = "1m";

      mkRcloneCryptRemoteWithMount =
        jobName: jobCfg: provider:
        (mkRcloneCryptRemote jobName jobCfg provider)
        // {
          mounts."/" = {
            enable = true;
            mountPoint =
              if jobCfg.mountPoint != null then
                jobCfg.mountPoint
              else
                "${hmArgs.config.home.homeDirectory}/${jobName}-${provider}";
            options = {
              read-only = jobCfg.readOnly;
              vfs-cache-mode = jobCfg.cacheMode;
              vfs-cache-max-age = cacheMaxAge;
              vfs-cache-max-size = cacheMaxSize;
              dir-cache-time = dirCacheTime;
              poll-interval = pollInterval;
            };
          };
        };

      mkRcloneCryptRemotes = lib.concatMapAttrs (
        jobName: jobCfg:
        lib.listToAttrs (
          map (provider: {
            name = mkCryptRemoteName jobName provider;
            value = mkRcloneCryptRemoteWithMount jobName jobCfg provider;
          }) jobCfg.providers
        )
      ) (lib.filterAttrs (_: jobCfg: jobCfg.encrypted) cfg.mounts);
    in
    {
      options.services.file-mount = {
        mounts = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                providers = lib.mkOption {
                  type = lib.types.nullOr (lib.types.listOf lib.types.str);
                  default = builtins.attrNames rcloneRemotes;
                  description = "List of rclone remotes to mount. If null, uses all defined remotes.";
                };

                destination = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Remote folder to mount. If null, uses mount name.";
                };

                mountPoint = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Local mount point. If null, uses home directory/<mount name>-<provider>.";
                };

                encrypted = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "Use client-side encryption (creates crypt remote)";
                };

                salt = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "Use salt for encryption (adds extra security layer). Only used when encrypted = true.";
                };

                passwordFile = lib.mkOption {
                  type = lib.types.nullOr lib.types.path;
                  default = null;
                  description = "Path to file containing the encryption password. Required when encrypted = true.";
                };

                saltFile = lib.mkOption {
                  type = lib.types.nullOr lib.types.path;
                  default = null;
                  description = "Path to file containing the encryption salt. Required when salt = true.";
                };

                readOnly = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "Mount as read-only";
                };

                cacheMode = lib.mkOption {
                  type = lib.types.enum [
                    "off"
                    "minimal"
                    "writes"
                    "full"
                  ];
                  default = "full";
                  description = "VFS cache mode: off (no cache), minimal (write only), writes (write cache), full (read+write cache)";
                };
              };
            }
          );
          default = { };
          description = "File mount mounts to configure";
        };
      };

      config = lib.mkIf (cfg.mounts != { }) {
        programs.rclone.enable = true;

        assertions = lib.flatten (
          lib.mapAttrsToList (name: mount: [
            {
              assertion = !mount.encrypted || mount.passwordFile != null;
              message = "file-mount: mount '${name}' has encrypted=true but no passwordFile set";
            }
            {
              assertion = !mount.salt || mount.saltFile != null;
              message = "file-mount: mount '${name}' has salt=true but no saltFile set";
            }
          ]) cfg.mounts
        );

        programs.rclone.remotes = mkRcloneCryptRemotes;
      };
    };
}
