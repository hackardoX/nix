{
  config,
  ...
}:
let
  sureFinanceUid = 905;
  sureFinanceGid = 905;
  sureFinanceUser = "sure-finance";
  sureFinanceGroup = "sure-finance";
  sureFinanceAppDir = "/var/lib/podman/sure-finance";
  sureFinanceDataDir = "/var/lib/data/sure-finance";

  hosts = config.flake.meta.reverse-proxy.hosts;
  reverseProxyPort = config.flake.meta.reverse-proxy.ports.sure-finance;
  sureFinanceImage = "ghcr.io/we-promise/sure:0.7.2";
  sureFinancePort = 3000;
  sureFinanceDbName = "sure_production";
  sureFinanceDbUser = "sure_user";
  sureFinanceOidcClientId = config.flake.meta.oidc-clients.sure-finance.clientId;
in
{
  flake.meta.homepage.services.sure-finance = {
    category = "Finance";
    name = "Sure Finance";
    description = "Personal Finance Tracker";
    icon = "sh-sure-finance.webp";
    href = "https://${hosts.finance}";
    siteMonitor = "http://localhost:${toString reverseProxyPort}/up";
    container = "sure-finance-web";
    dockerServer = "sure-finance";
    dockerSocketProxyPort = config.flake.meta.reverse-proxy.ports.sure-finance-docker-socket-proxy;
    pingPort = reverseProxyPort;
    widget = config.flake.lib.beszel.mkWidget {
      systemId = "Sure Finance";
    };
  };

  flake.meta.oidc-clients.sure-finance = {
    clientId = "sure-finance";
    clientName = "Sure Finance";
    policy = "two_factor";
    redirectUris = [ "https://${hosts.finance}/auth/openid_connect/callback" ];
    secretName = "autheliaSureFinanceOidcSecret";
    extraYamlLines = [
      ''token_endpoint_auth_method: "client_secret_basic"''
      "require_pkce: true"
      ''pkce_challenge_method: "S256"''
      ''access_token_signed_response_alg: "none"''
      ''userinfo_signed_response_alg: "none"''
    ];
  };

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
      "d ${sureFinanceDataDir} 0750 ${sureFinanceUser} ${sureFinanceGroup} -"
      "d ${sureFinanceDataDir}/postgresql 0750 ${sureFinanceUser} ${sureFinanceGroup} -"
      "d ${sureFinanceDataDir}/postgresql/data 0750 ${sureFinanceUser} ${sureFinanceGroup} -"
      "d ${sureFinanceDataDir}/postgresql/wal 0750 ${sureFinanceUser} ${sureFinanceGroup} -"
      "d ${sureFinanceDataDir}/redis 0750 ${sureFinanceUser} ${sureFinanceGroup} -"
    ];

    boot.initrd.impermanence.persist.directories = [
      {
        directory = sureFinanceAppDir;
        user = sureFinanceUser;
        group = sureFinanceGroup;
        mode = "0750";
      }
    ];

    home-manager.users.${sureFinanceUser} = {
      imports = with config.flake.modules.homeManager; [
        base
        backup
        podman-secrets
        homelab-docker-socket-proxy
        homelab-beszel-agent
        homelab-sure-finance
      ];
      home.username = sureFinanceUser;
      home.stateVersion = "26.05";
      services.homelab-docker-socket-proxy = {
        enable = true;
        port = config.flake.meta.reverse-proxy.ports.sure-finance-docker-socket-proxy;
      };
      services.homelab-beszel-agent = {
        enable = true;
        port = config.flake.meta.reverse-proxy.ports.beszel-agent-sure-finance;
      };
      services.rclone.remotes = [ "koofr" ];
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
        path = "/run/secrets/sure-finance/brand_fetch_client_id";
        reference = "op://HomeLab/Sure Finance/Brand Fetch/client id";
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
      sureFinanceOpenAiToken = {
        path = "/run/secrets/sure-finance/openai_token";
        reference = "op://HomeLab/Sure Finance/AI/api key";
        owner = sureFinanceUser;
        group = sureFinanceGroup;
      };
      sureFinanceActiveRecordPrimaryKey = {
        path = "/run/secrets/sure-finance/active_record_primary_key";
        reference = "op://HomeLab/Sure Finance/Encryption/primary key";
        owner = sureFinanceUser;
        group = sureFinanceGroup;
      };
      sureFinanceActiveRecordDeterministicKey = {
        path = "/run/secrets/sure-finance/active_record_deterministic_key";
        reference = "op://HomeLab/Sure Finance/Encryption/deterministic key";
        owner = sureFinanceUser;
        group = sureFinanceGroup;
      };
      sureFinanceActiveRecordKeyDerivationSalt = {
        path = "/run/secrets/sure-finance/active_record_key_derivation_salt";
        reference = "op://HomeLab/Sure Finance/Encryption/key derivation salt";
        owner = sureFinanceUser;
        group = sureFinanceGroup;
      };
      autheliaSureFinanceOidcSecret = {
        path = "/run/secrets/authelia/sure-finance_oidc_secret";
        reference = "op://HomeLab/Sure Finance/Authentication/OIDC client secret";
        owner = config.flake.meta.users.authelia.name;
        group = config.flake.meta.users.authelia.primaryGroup;
        services = [ "authelia-default.service" ];
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
        APP_DOMAIN = hosts.finance;
        AUTH_LOCAL_LOGIN_ENABLED = "false";
        DB_HOST = "db";
        DB_PORT = "5432";
        EMAIL_SENDER = "sure-finance@${config.flake.meta.reverse-proxy.domain}";
        EXCHANGE_RATE_PROVIDER = "twelve_data";
        OIDC_CLIENT_ID = sureFinanceOidcClientId;
        OIDC_ISSUER = "https://${hosts.auth}";
        OIDC_REDIRECT_URI = "https://${hosts.finance}/auth/openid_connect/callback";
        OIDC_BUTTON_LABEL = "Sign in with Authelia";
        OPENAI_MODEL = "mimo-v2.5-free";
        OPENAI_URI_BASE = "https://opencode.ai/zen/v1";
        ONBOARDING_STATE = "closed";
        POSTGRES_USER = sureFinanceDbUser;
        POSTGRES_DB = sureFinanceDbName;
        RAILS_ASSUME_SSL = "true";
        RAILS_FORCE_SSL = "false";
        REDIS_URL = "redis://redis:6379/1";
        SELF_HOSTED = "true";
        SMTP_ADDRESS = "smtp.resend.com";
        SMTP_PORT = "587";
        SMTP_USERNAME = "resend";
        SMTP_TLS_ENABLED = "true";
        SECURITIES_PROVIDER = "twelve_data";
        TZ = osConfig.time.timeZone;
      };

      sharedSecrets = {
        ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY =
          osConfig.services.onepassword-secrets.secretPaths.sureFinanceActiveRecordDeterministicKey;
        ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT =
          osConfig.services.onepassword-secrets.secretPaths.sureFinanceActiveRecordKeyDerivationSalt;
        ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY =
          osConfig.services.onepassword-secrets.secretPaths.sureFinanceActiveRecordPrimaryKey;
        BRAND_FETCH_CLIENT_ID =
          osConfig.services.onepassword-secrets.secretPaths.sureFinanceBrandFetchApiKey;
        OIDC_CLIENT_SECRET = osConfig.services.onepassword-secrets.secretPaths.sureFinanceOidcClientSecret;
        OPENAI_ACCESS_TOKEN = osConfig.services.onepassword-secrets.secretPaths.sureFinanceOpenAiToken;
        POSTGRES_PASSWORD = osConfig.services.onepassword-secrets.secretPaths.sureFinancePostgresPassword;
        SECRET_KEY_BASE = osConfig.services.onepassword-secrets.secretPaths.sureFinanceSecretKey;
        SMTP_PASSWORD = osConfig.services.onepassword-secrets.secretPaths.sureFinanceResendApiKey;
        TWELVE_DATA_API_KEY = osConfig.services.onepassword-secrets.secretPaths.sureFinanceTwelveDataApiKey;
      };
    in
    {
      config = {
        services.backup.jobs.sure-finance = {
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
          userNS = "keep-id:uid=999,gid=999";
          network = [ "sure-finance.network" ];
          networkAlias = [ "db" ];
          volumes = [
            "${sureFinanceDataDir}/postgresql/data:/var/lib/postgresql/data"
            "${sureFinanceDataDir}/postgresql/wal:/var/lib/postgresql/waldir"
          ];

          environment = {
            POSTGRES_USER = sureFinanceDbUser;
            POSTGRES_DB = sureFinanceDbName;
            POSTGRES_INITDB_ARGS = "--waldir=/var/lib/postgresql/waldir --data-checksums";
          };

          secrets = {
            POSTGRES_PASSWORD = osConfig.services.onepassword-secrets.secretPaths.sureFinancePostgresPassword;
          };

          extraConfig = {
            Service = {
              ExecStartPre = [
                "-/run/current-system/sw/bin/mkdir -p ${sureFinanceDataDir}/postgresql/data"
                "-/run/current-system/sw/bin/chown ${sureFinanceUser}:${sureFinanceGroup} ${sureFinanceDataDir}/postgresql/data"
                "-/run/current-system/sw/bin/mkdir -p ${sureFinanceDataDir}/postgresql/wal"
                "-/run/current-system/sw/bin/chown ${sureFinanceUser}:${sureFinanceGroup} ${sureFinanceDataDir}/postgresql/wal"
              ];
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
          image = "docker.io/library/redis:8.8.0";
          autoStart = true;
          userNS = "keep-id:uid=999,gid=999";
          network = [ "sure-finance.network" ];
          networkAlias = [ "redis" ];
          volumes = [ "${sureFinanceDataDir}/redis:/data" ];

          extraConfig = {
            Service = {
              ExecStartPre = [
                "-/run/current-system/sw/bin/mkdir -p ${sureFinanceDataDir}/redis"
                "-/run/current-system/sw/bin/chown ${sureFinanceUser}:${sureFinanceGroup} ${sureFinanceDataDir}/redis"
              ];
            };
            Container = {
              LogDriver = "journald";
              HealthCmd = "redis-cli ping";
              HealthInterval = "5s";
              HealthTimeout = "5s";
              HealthRetries = 5;
              NoNewPrivileges = true;
            };
          };
        };

        services.podman.containers.sure-finance-web = {
          image = sureFinanceImage;
          autoStart = true;
          userNS = "keep-id:uid=1000,gid=1000";
          network = [ "sure-finance.network" ];
          networkAlias = [ "web" ];
          volumes = [ "${sureFinanceAppDir}/storage:/rails/storage" ];
          ports = [ "${toString reverseProxyPort}:${toString sureFinancePort}" ];

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
          userNS = "keep-id:uid=1000,gid=1000";
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
