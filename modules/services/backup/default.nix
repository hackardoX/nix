{ lib, ... }:
{
  flake.modules.homeManager.homelab =
    hmArgs:
    let
      cfg = hmArgs.config.services.backup;
      rcloneRemotes = hmArgs.config.programs.rclone.remotes or { };

      retentionMap = {
        hourly = "--keep-within 1h";
        daily = "--keep-within 1d";
        weekly = "--keep-within 1w";
        monthly = "--keep-within 1m";
        yearly = "--keep-within 1y";
      };

      scheduleMap = {
        hourly = "hourly";
        daily = "daily";
        weekly = "weekly";
      };

      mkBackupName = jobName: provider: "${jobName}-${provider}";

      mkResticBackup =
        jobName: jobCfg: provider:
        let
          destination = if jobCfg.destination != null then jobCfg.destination else jobName;
        in
        {
          repository = "rclone:${provider}:${destination}/backup";
          passwordFile = hmArgs.config.programs.onepassword-secrets.secretPaths."backup-${jobName}".path;
          paths = jobCfg.paths;
          initialize = true;
          runCheck = true;
          checkOpts = [ "--read-data" ];
          pruneOpts = [ retentionMap.${jobCfg.retention} ];
          timerConfig = {
            OnCalendar = scheduleMap.${jobCfg.schedule};
            Persistent = true;
          };
        };

      mkSecrets = lib.mapAttrs' (
        jobName: _:
        lib.nameValuePair "backup-${jobName}" {
          path = ".secrets/backup/${jobName}/password";
          reference = "op://Homelab/Backup/${jobName}/password";
        }
      ) cfg.jobs;
    in
    {
      options.services.backup = {
        jobs = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                paths = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  description = "Paths to backup";
                };

                schedule = lib.mkOption {
                  type = lib.types.enum [
                    "hourly"
                    "daily"
                    "weekly"
                  ];
                  default = "daily";
                  description = "Backup schedule";
                };

                retention = lib.mkOption {
                  type = lib.types.enum [
                    "hourly"
                    "daily"
                    "weekly"
                    "monthly"
                    "yearly"
                  ];
                  default = "weekly";
                  description = "How long to keep backups (time-based retention)";
                };

                providers = lib.mkOption {
                  type = lib.types.nullOr (lib.types.listOf lib.types.str);
                  default = builtins.attrNames rcloneRemotes;
                  description = "List of rclone remotes to backup to.";
                };

                destination = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Destination folder on provider. If null, uses job name.";
                };
              };
            }
          );
          default = { };
          description = "Backup jobs to configure";
        };
      };

      config = lib.mkIf (cfg.jobs != { }) {
        programs.onepassword-secrets.secrets = mkSecrets;

        services.restic.backups = lib.concatMapAttrs (
          jobName: jobCfg:
          lib.genAttrs (map (provider: mkBackupName jobName provider) jobCfg.providers) (
            provider: mkResticBackup jobName jobCfg provider
          )
        ) cfg.jobs;
      };
    };
}
