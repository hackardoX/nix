{ config, lib, ... }:
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

  gatewaySocketDir = "/run/backup-gateway";
  gatewayUri = name: "rest:http+unix://${gatewaySocketDir}/${name}.sock:/";

  backrestRepos = lib.mapAttrsToList (name: repo: {
    id = name;
    inherit (repo) uri;
    env = [ "RESTIC_PASSWORD_FILE=${repo.passwordFile}" ];
    auto_initialize = true;
  }) config.flake.meta.backup.repos;
in
{
  flake.meta.homepage.services.backup = {
    category = "Monitoring";
    name = "Backrest";
    description = "Restic Backup Browser";
    icon = "mdi-backup-restore";
    href = "https://${hosts.backup}";
    siteMonitor = "http://localhost:${toString backrestPort}";
    # No credentials: Backrest's auth is disabled (see backrestConfig) and it
    # only listens on loopback behind the Caddy forward-auth.
    widget = {
      type = "backrest";
      url = "http://localhost:${toString backrestPort}";
    };
    pingPort = backrestPort;
  };

  # Backrest reads the repositories through the append-only gateway sockets
  # (services.backup-gateway.socketDir), not with the storage credentials. The
  # homelab/backup check keeps this in step with the NixOS option.
  flake.meta.backup.repos = {
    beszel = {
      uri = gatewayUri "beszel";
      passwordFile = "/run/secrets/beszel/backup_encryption_key";
    };
    immich = {
      uri = gatewayUri "immich";
      passwordFile = "/run/secrets/immich/backup_encryption_key";
    };
    job-ops = {
      uri = gatewayUri "job-ops";
      passwordFile = "/run/secrets/job-ops/backup_encryption_key";
    };
    sure-finance = {
      uri = gatewayUri "sure-finance";
      passwordFile = "/run/secrets/sure-finance/backup_encryption_key";
    };
    dawarich = {
      uri = gatewayUri "dawarich";
      passwordFile = "/run/secrets/dawarich/backup_encryption_key";
    };
    reactive-resume = {
      uri = gatewayUri "reactive-resume";
      passwordFile = "/run/secrets/reactive-resume/backup_encryption_key";
    };
    tandoor = {
      uri = gatewayUri "tandoor";
      passwordFile = "/run/secrets/tandoor/backup_encryption_key";
    };
  };

  flake.modules.nixos.homelab-backup =
    { pkgs, ... }:
    let
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
          "homelab-users"
          "beszel"
          "immich"
          "job-ops"
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
        ];
        requires = [ "systemd-tmpfiles-setup.service" ];
        wantedBy = [ "multi-user.target" ];

        environment = {
          BACKREST_CONFIG = "${backrestConfigDir}/config.json";
          BACKREST_DATA = backrestDataDir;
          BACKREST_RESTIC_COMMAND = "${pkgs.restic}/bin/restic";
          XDG_CACHE_HOME = backrestCacheDir;
          HOME = backrestDataDir;
        };

        serviceConfig = {
          Type = "simple";
          User = backrestUser;
          Group = backrestGroup;
          ExecStartPre = "${lib.getExe' pkgs.coreutils "test"} -x ${pkgs.backrest}/bin/backrest";
          ExecStart = "${pkgs.backrest}/bin/backrest -bind-address 127.0.0.1:${toString backrestPort}";
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
