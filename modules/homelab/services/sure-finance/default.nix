{
  config,
  lib,
  ...
}:
let
  sureFinanceUser = "sure-finance";
  sureFinanceGroup = "sure-finance";
  sureFinanceAppDir = "/var/lib/containers/sure-finance";
  sureFinanceDataDir = "/var/lib/data/sure-finance";

  domain = config.flake.meta.reverse-proxy.domain;
  hosts = config.flake.meta.reverse-proxy.hosts;
  reverseProxyPort = config.flake.meta.reverse-proxy.ports.sure-finance;
  mkHomepageLabels = config.flake.lib.mkHomepageLabels;

  sureFinanceImage = "ghcr.io/we-promise/sure:stable";
  sureFinancePort = 3000;
  sureFinanceDbName = "sure_production";
  sureFinanceDbUser = "sure_user";
  sureFinanceDbPasswordFile = "/run/secrets/sure-finance/postgres_password";
  sureFinanceSecretKeyBaseFile = "/run/secrets/sure-finance/secret_key";
  sureFinanceOpenaiTokenFile = "/run/secrets/sure-finance/openai_token";
in
{
  flake.modules.nixos.homelab-sure-finance = {
    users.users.${sureFinanceUser} = {
      isSystemUser = true;
      group = sureFinanceGroup;
      extraGroups = [
        "podman"
        "homelab-users"
        "rclone"
      ];
      createHome = true;
      home = "/var/lib/${sureFinanceUser}";
      autoSubUidGidRange = true;
      linger = true;
    };

    users.groups.${sureFinanceGroup} = { };

    systemd.tmpfiles.rules = [
      "d ${sureFinanceAppDir} 0750 ${sureFinanceUser} ${sureFinanceGroup} -"
      "d ${sureFinanceAppDir}/storage 0750 ${sureFinanceUser} ${sureFinanceGroup} -"
      "d ${sureFinanceDataDir}/postgres 0750 ${sureFinanceUser} ${sureFinanceGroup} -"
      "d ${sureFinanceAppDir}/containers 0750 ${sureFinanceUser} ${sureFinanceGroup} -"
    ];

    boot.initrd.impermanence.persist.directories = [
      {
        directory = sureFinanceAppDir;
        user = sureFinanceUser;
        group = sureFinanceGroup;
      }
    ];

    home-manager.users.${sureFinanceUser} = {
      services.rclone.remotes = [ "koofr" ];
      home.username = sureFinanceUser;
      home.stateVersion = "26.05";
      imports = with config.flake.modules.homeManager; [
        base
        backup
        podman-secrets
        homelab-sure-finance
      ];
    };

    services.onepassword-secrets.secrets = {
      sureFinanceSecretKey = {
        path = "/run/secrets/sure-finance/secret_key";
        reference = "op://HomeLab/Sure Finance/Authentication/secret key";
        owner = sureFinanceUser;
        group = sureFinanceGroup;
        services = [
          "podman-sure-finance-web.service"
          "podman-sure-finance-worker.service"
        ];
      };
      sureFinancePostgresPassword = {
        path = "/run/secrets/sure-finance/postgres_password";
        reference = "op://HomeLab/Sure Finance/Database/password";
        owner = sureFinanceUser;
        group = sureFinanceGroup;
        services = [ "podman-sure-finance-db.service" ];
      };
      sureFinanceOpenAiToken = {
        path = "/run/secrets/sure-finance/openai_token";
        reference = "op://HomeLab/Sure Finance/AI/api key";
        owner = sureFinanceUser;
        group = sureFinanceGroup;
        services = [
          "podman-sure-finance-web.service"
          "podman-sure-finance-worker.service"
        ];
      };
      backupSureFinanceEncryptionKey = {
        path = "/run/secrets/sure-finance/backup_encryption_key";
        reference = "op://Homelab/Backup/Sure Finance/password";
        owner = sureFinanceUser;
        group = sureFinanceGroup;
      };
    };

    services.caddy.virtualHosts."${hosts.finance}" = {
      extraConfig = ''
        import reverse_proxy_common
        reverse_proxy localhost:${toString reverseProxyPort}
      '';
    };
  };

  flake.modules.homeManager.homelab-sure-finance =
    hmArgs@{ osConfig, ... }:
    let
      sharedEnv = {
        POSTGRES_USER = sureFinanceDbUser;
        POSTGRES_DB = sureFinanceDbName;
        SELF_HOSTED = "true";
        RAILS_FORCE_SSL = "false";
        RAILS_ASSUME_SSL = "false";
        DB_HOST = "db";
        DB_PORT = "5432";
        REDIS_URL = "redis://redis:6379/1";
        TZ = osConfig.time.timeZone;
      };

      sharedSecrets = {
        POSTGRES_PASSWORD = sureFinanceDbPasswordFile;
        SECRET_KEY_BASE = sureFinanceSecretKeyBaseFile;
      }
      // lib.optionalAttrs (sureFinanceOpenaiTokenFile != null) {
        OPENAI_ACCESS_TOKEN = sureFinanceOpenaiTokenFile;
      };
    in
    {
      config = {
        xdg.configFile."containers/storage.conf".text = ''
          [storage]
          graphroot = "${sureFinanceAppDir}/containers"
        '';

        services.backup.jobs.sure-finance = {
          paths = [
            "${sureFinanceDataDir}/postgres"
            "${sureFinanceAppDir}/storage"
          ];
          schedule = "daily";
          retention = "standard";
          providers = [ "koofr" ];
          encryptionKey = osConfig.services.onepassword-secrets.secretPaths.backupSureFinanceEncryptionKey;
        };

        services.podman.enable = true;
        services.podman.networks.sure-finance.driver = "bridge";

        services.podman.containers.sure-finance-db = {
          image = "docker.io/library/postgres:16";
          autoStart = true;
          userNS = "keep-id";
          user = "%U";
          group = "%G";
          network = [ "sure-finance.network" ];
          networkAlias = [ "db" ];
          volumes = [ "${sureFinanceDataDir}/postgres:/var/lib/postgresql/data" ];

          environment = {
            POSTGRES_USER = sureFinanceDbUser;
            POSTGRES_DB = sureFinanceDbName;
          };

          secrets = {
            POSTGRES_PASSWORD = sureFinanceDbPasswordFile;
          };

          extraConfig = {
            Unit = {
              Wants = [ "opnix-secrets.service" ];
              After = [ "opnix-secrets.service" ];
            };
            Container = {
              LogDriver = "journald";
              HealthCmd = "pg_isready -U ${sureFinanceDbUser} -d ${sureFinanceDbName}";
              HealthInterval = "5s";
              HealthTimeout = "5s";
              HealthRetries = 5;
              NoNewPrivileges = true;
            };
          };
        };

        services.podman.containers.sure-finance-redis = {
          image = "docker.io/library/redis:latest";
          autoStart = true;
          userNS = "keep-id";
          user = "%U";
          group = "%G";
          network = [ "sure-finance.network" ];
          networkAlias = [ "redis" ];
          volumes = [ "${sureFinanceDataDir}/redis:/data" ];

          extraConfig.Container = {
            LogDriver = "journald";
            HealthCmd = "redis-cli ping";
            HealthInterval = "5s";
            HealthTimeout = "5s";
            HealthRetries = 5;
            NoNewPrivileges = true;
          };
        };

        services.podman.containers.sure-finance-web = {
          image = sureFinanceImage;
          autoStart = true;
          userNS = "keep-id";
          user = "%U";
          group = "%G";
          network = [ "sure-finance.network" ];
          networkAlias = [ "web" ];
          volumes = [ "${sureFinanceAppDir}/storage:/rails/storage" ];
          ports = [ "${toString reverseProxyPort}:${toString sureFinancePort}" ];

          labels = mkHomepageLabels {
            category = "Finance";
            name = "Sure Finance";
            description = "Personal Finance Tracker";
            icon = "mdi-cash-multiple";
            href = "http://localhost:${toString reverseProxyPort}";
          };

          environment = sharedEnv;
          secrets = sharedSecrets;

          extraConfig = {
            Unit = {
              Wants = [ "opnix-secrets.service" ];
              After = [
                "opnix-secrets.service"
                "podman-sure-finance-db.service"
                "podman-sure-finance-redis.service"
              ];
              Requires = [
                "podman-sure-finance-db.service"
                "podman-sure-finance-redis.service"
              ];
            };
            Container = {
              LogDriver = "journald";
              NoNewPrivileges = true;
              DNS = [
                "8.8.8.8"
                "1.1.1.1"
              ];
            };
          };
        };

        services.podman.containers.sure-finance-worker = {
          image = sureFinanceImage;
          autoStart = true;
          userNS = "keep-id";
          user = "%U";
          group = "%G";
          network = [ "sure-finance.network" ];
          networkAlias = [ "worker" ];
          volumes = [ "${sureFinanceAppDir}/storage:/rails/storage" ];

          exec = "bundle exec sidekiq";

          environment = sharedEnv;
          secrets = sharedSecrets;

          extraConfig = {
            Unit = {
              Wants = [ "opnix-secrets.service" ];
              After = [
                "opnix-secrets.service"
                "podman-sure-finance-db.service"
                "podman-sure-finance-redis.service"
              ];
              Requires = [
                "podman-sure-finance-db.service"
                "podman-sure-finance-redis.service"
              ];
            };
            Container = {
              LogDriver = "journald";
              NoNewPrivileges = true;
              DNS = [
                "8.8.8.8"
                "1.1.1.1"
              ];
            };
          };
        };
      };
    };
}
