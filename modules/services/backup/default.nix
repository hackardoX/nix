{ lib, ... }:
{
  flake.modules.homeManager.backup =
    hmArgs:
    let
      cfg = hmArgs.config.services.backup;
      rcloneRemotes = hmArgs.config.programs.rclone.remotes or { };

      retentionPresets = {
        short = [
          "--keep-daily 7"
          "--keep-weekly 4"
        ];
        standard = [
          "--keep-daily 7"
          "--keep-weekly 4"
          "--keep-monthly 3"
        ];
        extended = [
          "--keep-daily 7"
          "--keep-weekly 4"
          "--keep-monthly 6"
          "--keep-yearly 3"
        ];
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
          passwordFile = jobCfg.encryptionKey;
          paths = jobCfg.paths;
          initialize = true;
          runCheck = true;
          checkOpts = [ "--read-data" ];
          pruneOpts = retentionPresets.${jobCfg.retention};
          timerConfig = {
            OnCalendar = scheduleMap.${jobCfg.schedule};
            Persistent = true;
          };
        };
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
                    "short"
                    "standard"
                    "extended"
                  ];
                  default = "standard";
                  description = "Retention preset for backup snapshots";
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

                encryptionKey = lib.mkOption {
                  type = lib.types.path;
                  description = "Path to file containing the restic repository encryption key";
                };
              };
            }
          );
          default = { };
          description = "Backup jobs to configure";
        };
      };

      config = lib.mkIf (cfg.jobs != { }) {
        assertions = lib.flatten (
          lib.mapAttrsToList (name: job: {
            assertion = job.encryptionKey != null;
            message = "backup: job '${name}' has no encryptionKey set";
          }) cfg.jobs
        );

        services.restic = {
          enable = cfg.jobs != { };
          backups = lib.concatMapAttrs (
            jobName: jobCfg:
            lib.genAttrs (map (provider: mkBackupName jobName provider) jobCfg.providers) (
              provider: mkResticBackup jobName jobCfg provider
            )
          ) cfg.jobs;
        };
      };
    };
}
