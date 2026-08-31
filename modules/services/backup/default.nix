{ lib, config, ... }:
{
  flake.modules.nixos.backup =
    { config, ... }:
    let
      hmUsers = config.home-manager.users or { };
      allInstances = lib.concatLists (
        lib.mapAttrsToList (
          userName: userCfg:
          let
            instances = userCfg.services.postgresql-dump.instances or { };
          in
          lib.mapAttrsToList (name: instanceCfg: {
            user = userName;
            inherit (instanceCfg) backupDir;
          }) instances
        ) hmUsers
      );
    in
    {
      config = lib.mkIf (allInstances != [ ]) {
        systemd.tmpfiles.rules = lib.flatten (
          map (instance: [
            "d /var/lib/backups 0755 root root - -"
            "d ${dirOf instance.backupDir} 0750 ${instance.user} ${instance.user} - -"
            "d ${instance.backupDir} 0750 ${instance.user} ${instance.user} - -"
          ]) allInstances
        );
      };
    };

  flake.modules.homeManager.backup =
    hmArgs:
    let
      cfg = hmArgs.config.services.backup;
      rcloneRemotes = hmArgs.config.programs.rclone.remotes or { };
      dbOptions = config.flake.lib.types.backup.db;

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
          hasDb = jobCfg.db != null;
          dumpPath =
            if hasDb then hmArgs.config.services.postgresql-dump.instances.${jobName}.outputPath else null;
        in
        {
          repository = "rclone:${provider}:backup/${destination}";
          passwordFile = jobCfg.encryptionKey;
          paths = if hasDb then jobCfg.paths ++ [ dumpPath ] else jobCfg.paths;
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
      imports = [
        config.flake.modules.homeManager.rclone
      ];

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

                db = lib.mkOption {
                  type = lib.types.nullOr dbOptions;
                  default = null;
                  description = "Database configuration for automatic pre-backup dump";
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
            lib.listToAttrs (
              map (provider: {
                name = mkBackupName jobName provider;
                value = mkResticBackup jobName jobCfg provider;
              }) jobCfg.providers
            )
          ) cfg.jobs;
        };

        services.postgresql-dump.instances = lib.mapAttrs (_: jobCfg: {
          inherit (jobCfg.db)
            type
            user
            passwordFile
            container
            ;
        }) (lib.filterAttrs (_: jobCfg: jobCfg.db != null && jobCfg.db.type == "postgresql") cfg.jobs);

        systemd.user.services = lib.concatMapAttrs (
          name: jobCfg:
          builtins.listToAttrs (
            map (provider: {
              name = "restic-backups-${mkBackupName name provider}";
              value = {
                Unit = {
                  After = [ "postgresql-dump-${name}.service" ];
                  Requires = [ "postgresql-dump-${name}.service" ];
                };
              };
            }) jobCfg.providers
          )
        ) (lib.filterAttrs (_: jobCfg: jobCfg.db != null && jobCfg.db.type == "postgresql") cfg.jobs);
      };
    };
}
