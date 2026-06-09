{
  config,
  lib,
  ...
}:
{
  flake.modules.homeManager.base =
    hmArgs:
    let
      cfg = hmArgs.config.services.file-mount;
      rcloneRemotes = hmArgs.config.programs.rclone.remotes or { };

      cacheMaxAge = "720h";
      cacheMaxSize = "10G";
      dirCacheTime = "5m";
      pollInterval = "1m";

      mkCryptRemoteName = jobName: provider: "${provider}-crypt-${jobName}";
      mkSecretName = jobName: "fileMount${config.flake.lib.capitalize jobName}";

      mkRcloneCryptRemote =
        jobName: jobCfg: provider:
        let
          destination = if jobCfg.destination != null then jobCfg.destination else jobName;
        in
        {
          config = {
            type = "crypt";
            remote = "${provider}:${destination}";
            filename_encryption = "standard";
            directory_name_encryption = "true";
          };
          secrets = {
            password = hmArgs.config.programs.onepassword-secrets.secretPaths."${mkSecretName jobName}";
          }
          // lib.optionalAttrs jobCfg.salt {
            password2 = hmArgs.config.programs.onepassword-secrets.secretPaths."${mkSecretName jobName}Salt";
          };
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

      mkSecrets = lib.concatMapAttrs (
        jobName: jobCfg:
        let
          passwordSecret = {
            "${mkSecretName jobName}" = {
              path = ".secrets/file-mount/${jobName}/password";
              reference = "op://Homelab/File Mount/${jobName}/password";
            };
          };
          saltSecret = lib.optionalAttrs jobCfg.salt {
            "${mkSecretName jobName}Salt" = {
              path = ".secrets/file-mount/${jobName}/salt";
              reference = "op://Homelab/File Mount/${jobName}/salt";
            };
          };
        in
        lib.optionalAttrs jobCfg.encrypted (passwordSecret // saltSecret)
      ) cfg.mounts;

      mkRcloneCryptRemotes = lib.concatMapAttrs (
        jobName: jobCfg:
        lib.listToAttrs (
          map (provider: {
            name = mkCryptRemoteName jobName provider;
            value = mkRcloneCryptRemote jobName jobCfg provider;
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
                  description = "Use salt for encryption (adds extra security layer). Salt value stored in 1Password. Only used when encrypted = true.";
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
        programs.onepassword-secrets.secrets = mkSecrets;
        programs.rclone.remotes = mkRcloneCryptRemotes;
      };
    };
}
