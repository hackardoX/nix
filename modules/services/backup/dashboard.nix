{
  config,
  lib,
  ...
}:
let
  backrestUid = 920;
  backrestGid = 920;
  backrestUser = "backrest";
  backrestGroup = "backrest";
  backrestDataDir = "/var/lib/backrest";
  backrestConfigDir = "/var/lib/backrest/config";
  backrestCacheDir = "/var/lib/backrest/cache";

  hosts = config.flake.meta.reverse-proxy.hosts;
  backrestPort = config.flake.meta.reverse-proxy.ports.backup;
in
{
  flake.meta.homepage.services.backup = {
    category = "Monitoring";
    name = "Backrest";
    description = "Restic Backup Browser";
    icon = "mdi-backup-restore";
    href = "https://${hosts.backup}";
    siteMonitor = "http://localhost:${toString backrestPort}";
    pingPort = backrestPort;
  };

  flake.modules.nixos.homelab-backup =
    { pkgs, ... }:
    let
      repos = {
        beszel = {
          uri = "rclone:koofr:backup/beszel";
          passwordFile = "/run/secrets/beszel/backup_encryption_key";
        };
        immich = {
          uri = "rclone:koofr:backup/immich";
          passwordFile = "/run/secrets/immich/backup_encryption_key";
        };
        job-ops = {
          uri = "rclone:koofr:backup/job-ops";
          passwordFile = "/run/secrets/job-ops/backup_encryption_key";
        };
        sure-finance = {
          uri = "rclone:koofr:backup/sure-finance";
          passwordFile = "/run/secrets/sure-finance/backup_encryption_key";
        };
        dawarich = {
          uri = "rclone:koofr:backup/dawarich";
          passwordFile = "/run/secrets/dawarich/backup_encryption_key";
        };
        reactive-resume = {
          uri = "rclone:koofr:backup/reactive-resume";
          passwordFile = "/run/secrets/reactive-resume/backup_encryption_key";
        };
        tandoor = {
          uri = "rclone:koofr:backup/tandoor";
          passwordFile = "/run/secrets/tandoor/backup_encryption_key";
        };
      };

      backrestRepos = lib.mapAttrsToList (name: repo: {
        id = name;
        inherit (repo) uri;
        env = [ "RESTIC_PASSWORD_FILE=${repo.passwordFile}" ];
        auto_initialize = true;
      }) repos;

      backrestConfig = pkgs.writeText "backrest-config.json" (
        builtins.toJSON {
          modno = 1;
          version = 6;
          instance = "HomeLab";
          repos = backrestRepos;
          auth = {
            disabled = true;
          };
        }
      );
    in
    {
      users.users.${backrestUser} = {
        uid = backrestUid;
        isSystemUser = true;
        group = backrestGroup;
        extraGroups = [
          "rclone"
          "homelab-users"
          "beszel"
          "immich"
          "job-ops"
          "monitoring"
          "sure-finance"
          "dawarich"
          "reactive-resume"
          "tandoor"
        ];
        home = backrestDataDir;
        createHome = true;
        autoSubUidGidRange = true;
        linger = true;
      };

      users.groups.${backrestGroup} = {
        gid = backrestGid;
      };

      systemd.tmpfiles.rules = [
        "d ${backrestDataDir} 0750 ${backrestUser} ${backrestGroup} -"
        "d ${backrestConfigDir} 0750 ${backrestUser} ${backrestGroup} -"
        "d ${backrestCacheDir} 0750 ${backrestUser} ${backrestGroup} -"
      ];

      home-manager.users.${backrestUser} = {
        services.rclone.remotes = [ "koofr" ];
        home.username = backrestUser;
        home.stateVersion = "26.05";
        imports = with config.flake.modules.homeManager; [
          base
          backup
        ];
      };

      systemd.services.backrest = {
        description = "Backrest - Restic Web UI";
        after = [
          "network.target"
          "systemd-tmpfiles-setup.service"
          "opnix-secrets.service"
        ];
        requires = [
          "systemd-tmpfiles-setup.service"
          "opnix-secrets.service"
        ];
        wantedBy = [ "multi-user.target" ];

        environment = {
          BACKREST_CONFIG = "${backrestConfigDir}/config.json";
          BACKREST_DATA = backrestDataDir;
          BACKREST_RESTIC_COMMAND = lib.getExe pkgs.restic;
          XDG_CACHE_HOME = backrestCacheDir;
          HOME = backrestDataDir;
        };

        serviceConfig = {
          Type = "simple";
          User = backrestUser;
          Group = backrestGroup;
          ExecStartPre = "${lib.getExe' pkgs.coreutils "test"} -x ${lib.getExe pkgs.backrest}";
          ExecStart = "${lib.getExe pkgs.backrest} -bind-address 127.0.0.1:${toString backrestPort}";
          Restart = "on-failure";
          RestartSec = "10";

          StandardOutput = "journal";
          StandardError = "journal";
          SyslogIdentifier = "backrest";

          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [
            backrestDataDir
            backrestConfigDir
            backrestCacheDir
          ];
          ReadOnlyPaths = [ "/run/secrets" ];
        };

        preStart = ''
          cp ${backrestConfig} ${backrestConfigDir}/config.json
          chown ${backrestUser}:${backrestGroup} ${backrestConfigDir}/config.json
          chmod 640 ${backrestConfigDir}/config.json
        '';
      };

      services.caddy.virtualHosts."${hosts.backup}" = {
        extraConfig = ''
          import auth_protected
          import reverse_proxy_common
          reverse_proxy localhost:${toString backrestPort}
        '';
      };
    };
}
