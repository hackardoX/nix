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
  sureFinanceImage = "ghcr.io/we-promise/sure:0.7.3";
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

    sops.secrets = {
      "sure-finance/secret_key" = {
        owner = sureFinanceUser;
        group = sureFinanceGroup;
      };
      "sure-finance/postgres_password" = {
        owner = sureFinanceUser;
        group = sureFinanceGroup;
      };
      "sure-finance/backup_encryption_key" = {
        owner = sureFinanceUser;
        group = sureFinanceGroup;
        mode = "0640";
      };
      "sure-finance/resend_api_key" = {
        owner = sureFinanceUser;
        group = sureFinanceGroup;
      };
      "sure-finance/brand_fetch_client_id" = {
        owner = sureFinanceUser;
        group = sureFinanceGroup;
      };
      "sure-finance/twelve_data_api_key" = {
        owner = sureFinanceUser;
        group = sureFinanceGroup;
      };
      "sure-finance/oidc_client_secret" = {
        owner = sureFinanceUser;
        group = sureFinanceGroup;
      };
      "sure-finance/openai_token" = {
        owner = sureFinanceUser;
        group = sureFinanceGroup;
      };
      "sure-finance/active_record_primary_key" = {
        owner = sureFinanceUser;
        group = sureFinanceGroup;
      };
      "sure-finance/active_record_deterministic_key" = {
        owner = sureFinanceUser;
        group = sureFinanceGroup;
      };
      "sure-finance/active_record_key_derivation_salt" = {
        owner = sureFinanceUser;
        group = sureFinanceGroup;
      };
      "authelia_oidc/sure-finance" = {
        owner = config.flake.meta.users.authelia.name;
        group = config.flake.meta.users.authelia.primaryGroup;
        restartUnits = [ "authelia-default.service" ];
      };
    };

    services.caddy.virtualHosts."${hosts.finance}" = {
      extraConfig = ''
        import auth_protected
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
        OPENAI_MODEL = "mimo-v2.5";
        OPENAI_URI_BASE = "https://opencode.ai/zen/go/v1";
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
          osConfig.sops.secrets."sure-finance/active_record_deterministic_key".path;
        ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT =
          osConfig.sops.secrets."sure-finance/active_record_key_derivation_salt".path;
        ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY =
          osConfig.sops.secrets."sure-finance/active_record_primary_key".path;
        BRAND_FETCH_CLIENT_ID = osConfig.sops.secrets."sure-finance/brand_fetch_client_id".path;
        OIDC_CLIENT_SECRET = osConfig.sops.secrets."sure-finance/oidc_client_secret".path;
        OPENAI_ACCESS_TOKEN = osConfig.sops.secrets."sure-finance/openai_token".path;
        POSTGRES_PASSWORD = osConfig.sops.secrets."sure-finance/postgres_password".path;
        SECRET_KEY_BASE = osConfig.sops.secrets."sure-finance/secret_key".path;
        SMTP_PASSWORD = osConfig.sops.secrets."sure-finance/resend_api_key".path;
        TWELVE_DATA_API_KEY = osConfig.sops.secrets."sure-finance/twelve_data_api_key".path;
      };
    in
    {
      config = {
        services.backup.jobs.sure-finance = {
          schedule = "daily";
          retention = "standard";
          providers = [ "koofr" ];
          encryptionKey = osConfig.sops.secrets."sure-finance/backup_encryption_key".path;
          db = {
            type = "postgresql";
            user = "sure_user";
            passwordFile = osConfig.sops.secrets."sure-finance/postgres_password".path;
            container = {
              type = "podman";
              name = "sure-finance-db";
            };
          };
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
            POSTGRES_PASSWORD = osConfig.sops.secrets."sure-finance/postgres_password".path;
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
