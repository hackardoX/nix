{
  config,
  lib,
  ...
}:
let
  sureFinanceUid = 905;
  sureFinanceGid = 905;
  sureFinanceUser = "sure-finance";
  sureFinanceGroup = "sure-finance";
  sureFinanceAppDir = "/var/lib/containers/sure-finance";
  sureFinanceDataDir = "/var/lib/data/sure-finance";

  hosts = config.flake.meta.reverse-proxy.hosts;
  reverseProxyPort = config.flake.meta.reverse-proxy.ports.sure-finance;
  mkHomepageLabels = config.flake.lib.mkHomepageLabels;

  sureFinanceImage = "ghcr.io/we-promise/sure:0.7.2";
  sureFinancePort = 3000;
  sureFinanceDbName = "sure_production";
  sureFinanceDbUser = "sure_user";
  sureFinanceDbPasswordFile = "/run/secrets/sure-finance/postgres_password";
  sureFinanceSecretKeyBaseFile = "/run/secrets/sure-finance/secret_key";
  sureFinanceOpenaiTokenFile = "/run/secrets/sure-finance/openai_token";
  sureFinanceResendApiKeyFile = "/run/secrets/sure-finance/resend_api_key";
  sureFinanceBrandFetchApiKeyFile = "/run/secrets/sure-finance/brand_fetch_api_key";
  sureFinanceTwelveDataApiKeyFile = "/run/secrets/sure-finance/twelve_data_api_key";
  sureFinanceOidcClientId = config.flake.meta.oidc-clients.sure-finance.clientId or "";
  sureFinanceOidcSecretFile = "/run/secrets/sure-finance/oidc_client_secret";
in
{
  flake.modules.nixos.homelab-sure-finance = {
    users.users.${sureFinanceUser} = {
      uid = sureFinanceUid;
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

    users.groups.${sureFinanceGroup} = {
      gid = sureFinanceGid;
    };

    systemd.tmpfiles.rules = [
      "d ${sureFinanceAppDir} 0750 ${sureFinanceUser} ${sureFinanceGroup} -"
      "d ${sureFinanceAppDir}/storage 0750 ${sureFinanceUser} ${sureFinanceGroup} -"
      "d ${sureFinanceDataDir}/postgres 0750 ${sureFinanceUser} ${sureFinanceGroup} -"
      "d ${sureFinanceDataDir}/redis 0750 ${sureFinanceUser} ${sureFinanceGroup} -"
      "d ${sureFinanceAppDir}/containers 0750 ${sureFinanceUser} ${sureFinanceGroup} -"
    ];

    systemd.services."home-manager-${sureFinanceUser}" = {
      after = [ "user@${toString sureFinanceUid}.service" ];
      wants = [ "user@${toString sureFinanceUid}.service" ];
    };

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
      };
      sureFinancePostgresPassword = {
        path = "/run/secrets/sure-finance/postgres_password";
        reference = "op://HomeLab/Sure Finance/Database/password";
        owner = sureFinanceUser;
        group = sureFinanceGroup;
      };
      sureFinanceOpenAiToken = {
        path = "/run/secrets/sure-finance/openai_token";
        reference = "op://HomeLab/Sure Finance/AI/api key";
        owner = sureFinanceUser;
        group = sureFinanceGroup;
      };
      backupSureFinanceEncryptionKey = {
        path = "/run/secrets/sure-finance/backup_encryption_key";
        reference = "op://Homelab/Backup/Sure Finance/password";
        owner = sureFinanceUser;
        group = sureFinanceGroup;
      };
      sureFinanceResendApiKey = {
        path = "/run/secrets/sure-finance/resend_api_key";
        reference = "op://HomeLab/Sure Finance/Resend/api key";
        owner = sureFinanceUser;
        group = sureFinanceGroup;
      };
      sureFinanceBrandFetchApiKey = {
        path = "/run/secrets/sure-finance/brand_fetch_api_key";
        reference = "op://HomeLab/Sure Finance/Brand Fetch/api key";
        owner = sureFinanceUser;
        group = sureFinanceGroup;
      };
      sureFinanceTwelveDataApiKey = {
        path = "/run/secrets/sure-finance/twelve_data_api_key";
        reference = "op://HomeLab/Sure Finance/Twelve Data/api key";
        owner = sureFinanceUser;
        group = sureFinanceGroup;
      };
      sureFinanceOidcClientSecret = {
        path = "/run/secrets/sure-finance/oidc_client_secret";
        reference = "op://HomeLab/Sure Finance/Authentication/OIDC client secret";
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
    { osConfig, ... }:
    let
      sharedEnv = {
        POSTGRES_USER = sureFinanceDbUser;
        POSTGRES_DB = sureFinanceDbName;
        SELF_HOSTED = "true";
        # TODO: switch to "invite_only" after creating the first admin
        ONBOARDING_STATE = "open";
        RAILS_FORCE_SSL = "false";
        RAILS_ASSUME_SSL = "true";
        DB_HOST = "db";
        DB_PORT = "5432";
        REDIS_URL = "redis://redis:6379/1";
        APP_DOMAIN = hosts.finance;
        SMTP_ADDRESS = "smtp.resend.com";
        SMTP_PORT = "587";
        SMTP_USERNAME = "resend";
        SMTP_TLS_ENABLED = "true";
        EMAIL_SENDER = "sure-finance@${osConfig.flake.meta.reverse-proxy.domain}";
        EXCHANGE_RATE_PROVIDER = "twelve_data";
        SECURITIES_PROVIDER = "twelve_data";
        TZ = osConfig.time.timeZone;
      }
      // lib.optionalAttrs (sureFinanceOidcSecretFile != null) {
        OIDC_CLIENT_ID = sureFinanceOidcClientId;
        OIDC_ISSUER = "https://${hosts.auth}";
        OIDC_REDIRECT_URI = "https://${hosts.finance}/auth/openid_connect/callback";
      };

      sharedSecrets = {
        POSTGRES_PASSWORD = sureFinanceDbPasswordFile;
        SECRET_KEY_BASE = sureFinanceSecretKeyBaseFile;
        SMTP_PASSWORD = sureFinanceResendApiKeyFile;
        BRAND_FETCH_CLIENT_ID = sureFinanceBrandFetchApiKeyFile;
        TWELVE_DATA_API_KEY = sureFinanceTwelveDataApiKeyFile;
      }
      // lib.optionalAttrs (sureFinanceOpenaiTokenFile != null) {
        OPENAI_ACCESS_TOKEN = sureFinanceOpenaiTokenFile;
      }
      // lib.optionalAttrs (sureFinanceOidcSecretFile != null) {
        OIDC_CLIENT_SECRET = sureFinanceOidcSecretFile;
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
          image = "docker.io/library/postgres:16.14";
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
          image = "docker.io/library/redis:8.8.0";
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
            icon = "sh-sure-finance-dark.webp";
            href = "http://localhost:${toString reverseProxyPort}";
            siteMonitor = "http://localhost:${toString reverseProxyPort}/up";
          };

          environment = sharedEnv;
          secrets = sharedSecrets;

          extraConfig = {
            Unit = {
              After = [
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
              HealthCmd = "curl -sf http://localhost:${toString sureFinancePort}/up || exit 1";
              HealthInterval = "30s";
              HealthTimeout = "10s";
              HealthRetries = 3;
              NoNewPrivileges = true;
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
              After = [
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
              HealthCmd = "ps aux | grep -q '[s]idekiq' || exit 1";
              HealthInterval = "30s";
              HealthTimeout = "10s";
              HealthRetries = 3;
              NoNewPrivileges = true;
            };
          };
        };
      };
    };
}
