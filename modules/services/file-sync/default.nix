{
  config,
  lib,
  ...
}:
{
  flake.modules.homeManager.base =
    hmArgs@{ pkgs, ... }:
    let
      cfg = hmArgs.config.services.file-sync;
      rcloneRemotes = hmArgs.config.programs.rclone.remotes or { };

      scheduleMap = {
        hourly = "hourly";
        daily = "daily";
        weekly = "weekly";
      };

      mkSyncJobName = jobName: provider: "${jobName}-${provider}";
      mkCryptRemoteName = jobName: provider: "${provider}-crypt-${jobName}";
      mkSecretName = jobName: "fileSync${config.flake.lib.capitalize jobName}";

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
            password = hmArgs.config.programs.onepassword-secrets.secretPaths."${mkSecretName jobName}".path;
          }
          // lib.optionalAttrs jobCfg.salt {
            password2 =
              hmArgs.config.programs.onepassword-secrets.secretPaths."${mkSecretName jobName}Salt".path;
          };

        };

      mkSyncCommand =
        jobName: jobCfg: provider:
        let
          destination = if jobCfg.destination != null then jobCfg.destination else jobName;
          remote =
            if jobCfg.encrypted then
              "${mkCryptRemoteName jobName provider}:${destination}"
            else
              "${provider}:${destination}";

          deleteFlag = if jobCfg.delete then "--delete" else "";
          excludeFlags = lib.concatMapStringsSep " " (p: "--exclude '${p}'") jobCfg.exclude;

          resyncCheck = pkgs.writeShellScript "check-resync-${jobName}-${provider}" ''
            CACHE_DIR="$HOME/.cache/rclone/bisync"
            PATH_HASH=$(echo "${jobCfg.source}-${remote}" | md5sum | cut -d' ' -f1)
            if [ ! -d "$CACHE_DIR/$PATH_HASH" ]; then
              echo "--resync"
            fi
          '';
        in
        if jobCfg.direction == "push" then
          "${pkgs.rclone}/bin/rclone copy ${jobCfg.source} ${remote} ${deleteFlag} ${excludeFlags}"
        else if jobCfg.direction == "pull" then
          "${pkgs.rclone}/bin/rclone copy ${remote} ${jobCfg.source} ${deleteFlag} ${excludeFlags}"
        else
          "${pkgs.rclone}/bin/rclone bisync ${jobCfg.source} ${remote} --resilient --conflict-resolve newer $(${resyncCheck}) ${excludeFlags}";

      mkSecrets = lib.concatMapAttrs (
        jobName: jobCfg:
        let
          passwordSecret = {
            "${mkSecretName jobName}" = {
              path = ".secrets/file-sync/${jobName}/password";
              reference = "op://Homelab/File Sync/${jobName}/password";
            };
          };
          saltSecret = lib.optionalAttrs jobCfg.salt {
            "${mkSecretName jobName}Salt" = {
              path = ".secrets/file-sync/${jobName}/salt";
              reference = "op://Homelab/File Sync/${jobName}/salt";
            };
          };
        in
        lib.optionalAttrs jobCfg.encrypted (passwordSecret // saltSecret)
      ) cfg.jobs;

      mkRcloneCryptRemotes = lib.concatMapAttrs (
        jobName: jobCfg:
        lib.genAttrs (map (provider: mkCryptRemoteName jobName provider) jobCfg.providers) (
          provider: mkRcloneCryptRemote jobName jobCfg provider
        )
      ) (lib.filterAttrs (_: jobCfg: jobCfg.encrypted) cfg.jobs);

      mkSystemdServices = lib.concatMapAttrs (
        jobName: jobCfg:
        lib.genAttrs (map (provider: mkSyncJobName jobName provider) jobCfg.providers) (provider: {
          description = "File sync: ${jobName} to ${provider}";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = mkSyncCommand jobName jobCfg provider;
          };
        })
      ) cfg.jobs;

      mkSystemdTimers = lib.concatMapAttrs (
        jobName: jobCfg:
        lib.genAttrs (map (provider: mkSyncJobName jobName provider) jobCfg.providers) (provider: {
          description = "Timer for file sync: ${jobName} to ${provider}";
          timerConfig = {
            OnCalendar = scheduleMap.${jobCfg.schedule};
            Persistent = true;
          };
          wantedBy = [ "timers.target" ];
        })
      ) cfg.jobs;
    in
    {
      options.services.file-sync = {
        jobs = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                source = lib.mkOption {
                  type = lib.types.str;
                  description = "Local path to sync";
                };

                providers = lib.mkOption {
                  type = lib.types.nullOr (lib.types.listOf lib.types.str);
                  default = builtins.attrNames rcloneRemotes;
                  description = "List of rclone remotes to sync to. If null, uses all defined remotes.";
                };

                destination = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Destination folder on provider. If null, uses job name.";
                };

                direction = lib.mkOption {
                  type = lib.types.enum [
                    "push"
                    "pull"
                    "sync"
                  ];
                  default = "sync";
                  description = "Sync direction: push (local→remote), pull (remote→local), sync (bidirectional)";
                };

                schedule = lib.mkOption {
                  type = lib.types.enum [
                    "hourly"
                    "daily"
                    "weekly"
                  ];
                  default = "daily";
                  description = "Sync schedule";
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

                delete = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                  description = "Delete files on destination that don't exist on source";
                };

                exclude = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "Patterns to exclude from sync";
                };
              };
            }
          );
          default = { };
          description = "File sync jobs to configure";
        };
      };

      config = lib.mkIf (cfg.jobs != { }) {
        programs.onepassword-secrets.secrets = mkSecrets;

        programs.rclone.remotes = mkRcloneCryptRemotes;

        systemd.user.services = lib.mapAttrs' (
          name: service: lib.nameValuePair "file-sync-${name}" service
        ) mkSystemdServices;

        systemd.user.timers = lib.mapAttrs' (
          name: timer: lib.nameValuePair "file-sync-${name}" timer
        ) mkSystemdTimers;
      };
    };
}
