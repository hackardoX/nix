{
  config,
  ...
}:
let
  dawarichUid = 909;
  dawarichGid = 909;
  dawarichUser = "dawarich";
  dawarichGroup = "dawarich";
  dawarichAppDir = "/var/lib/podman/dawarich";
  dawarichDataDir = "/var/lib/data/dawarich";

  hosts = config.flake.meta.reverse-proxy.hosts;
  domain = config.flake.meta.reverse-proxy.domain;
  reverseProxyPort = config.flake.meta.reverse-proxy.ports.dawarich;
  dawarichImage = "docker.io/freikin/dawarich:1.12.0";
  dawarichPort = 3000;
  dawarichDbName = "dawarich";
  dawarichDbUser = "dawarich";
in
{
  flake.meta.homepage.services.dawarich = {
    category = "General";
    name = "Dawarich";
    description = "Location History Tracker";
    icon = "sh-dawarich.webp";
    href = "https://${hosts.timeline}";
    siteMonitor = "http://localhost:${toString reverseProxyPort}/api/v1/health";
    container = "dawarich-app";
    dockerServer = "dawarich";
    dockerSocketProxyPort = config.flake.meta.reverse-proxy.ports.dawarich-docker-socket-proxy;
    pingPort = reverseProxyPort;
    widget = config.flake.lib.beszel.mkWidget {
      systemId = "Dawarich";
    };
  };

  flake.meta.oidc-clients.dawarich = {
    clientId = "dawarich";
    clientName = "Dawarich";
    policy = "two_factor";
    redirectUris = [ "https://${hosts.timeline}/users/auth/openid_connect/callback" ];
    secretName = "autheliaDawarichOidcSecret";
    extraYamlLines = [
      ''token_endpoint_auth_method: "client_secret_basic"''
    ];
  };

  flake.modules.nixos.homelab-dawarich = {
    users.users.${dawarichUser} = {
      uid = dawarichUid;
      isSystemUser = true;
      group = dawarichGroup;
      extraGroups = [
        "podman"
        "homelab-users"
        "rclone"
      ];
      createHome = true;
      home = "/var/lib/${dawarichUser}";
      autoSubUidGidRange = true;
      linger = true;
    };

    users.groups.${dawarichGroup} = {
      gid = dawarichGid;
    };

    systemd.tmpfiles.rules = [
      "d ${dawarichAppDir} 0750 ${dawarichUser} ${dawarichGroup} -"
      "d ${dawarichAppDir}/public 0750 ${dawarichUser} ${dawarichGroup} -"
      "d ${dawarichAppDir}/watched 0750 ${dawarichUser} ${dawarichGroup} -"
      "d ${dawarichAppDir}/storage 0750 ${dawarichUser} ${dawarichGroup} -"
      "d ${dawarichDataDir} 0750 ${dawarichUser} ${dawarichGroup} -"
      "d ${dawarichDataDir}/db_data 0750 ${dawarichUser} ${dawarichGroup} -"
      "d ${dawarichDataDir}/postgresql 0750 ${dawarichUser} ${dawarichGroup} -"
      "d ${dawarichDataDir}/postgresql/data 0750 ${dawarichUser} ${dawarichGroup} -"
      "d ${dawarichDataDir}/postgresql/wal 0750 ${dawarichUser} ${dawarichGroup} -"
      "d ${dawarichDataDir}/redis 0750 ${dawarichUser} ${dawarichGroup} -"
    ];

    boot.initrd.impermanence.persist.directories = [
      {
        directory = dawarichAppDir;
        user = dawarichUser;
        group = dawarichGroup;
        mode = "0750";
      }
    ];

    home-manager.users.${dawarichUser} = {
      imports = with config.flake.modules.homeManager; [
        base
        backup
        podman-secrets
        homelab-docker-socket-proxy
        homelab-beszel-agent
        homelab-dawarich
      ];
      home.username = dawarichUser;
      home.stateVersion = "26.05";
      services.rclone.remotes = [ "koofr" ];
      services.homelab-docker-socket-proxy = {
        enable = true;
        port = config.flake.meta.reverse-proxy.ports.dawarich-docker-socket-proxy;
      };
      services.homelab-beszel-agent = {
        enable = true;
        port = config.flake.meta.reverse-proxy.ports.beszel-agent-dawarich;
      };
    };

    services.onepassword-secrets.secrets = {
      dawarichSecretKeyBase = {
        path = "/run/secrets/dawarich/secret_key_base";
        reference = "op://Homelab/Dawarich/Authentication/secret key";
        owner = dawarichUser;
        group = dawarichGroup;
      };
      dawarichDbPassword = {
        path = "/run/secrets/dawarich/db_password";
        reference = "op://Homelab/Dawarich/Database/password";
        owner = dawarichUser;
        group = dawarichGroup;
      };
      dawarichOidcClientSecret = {
        path = "/run/secrets/dawarich/oidc_client_secret";
        reference = "op://Homelab/Dawarich/Authentication/OIDC client secret";
        owner = dawarichUser;
        group = dawarichGroup;
      };
      dawarichResendApiKey = {
        path = "/run/secrets/dawarich/resend_api_key";
        reference = "op://Homelab/Dawarich/Resend/api key";
        owner = dawarichUser;
        group = dawarichGroup;
      };
      backupDawarichEncryptionKey = {
        path = "/run/secrets/dawarich/backup_encryption_key";
        reference = "op://Homelab/Backup/Dawarich/password";
        owner = dawarichUser;
        group = dawarichGroup;
        mode = "0640";
      };
      autheliaDawarichOidcSecret = {
        path = "/run/secrets/authelia/dawarich_oidc_secret";
        reference = "op://HomeLab/Dawarich/Authentication/OIDC client secret";
        owner = config.flake.meta.users.authelia.name;
        group = config.flake.meta.users.authelia.primaryGroup;
        services = [ "authelia-default.service" ];
      };
    };

    services.caddy.virtualHosts."${hosts.timeline}" = {
      extraConfig = ''
        import reverse_proxy_common
        reverse_proxy localhost:${toString reverseProxyPort}
      '';
    };
  };

  flake.modules.homeManager.homelab-dawarich =
    { osConfig, ... }:
    let
      sharedEnv = {
        ALLOW_EMAIL_PASSWORD_LOGIN = false;
        ALLOW_EMAIL_PASSWORD_REGISTRATION = false;
        APPLICATION_HOSTS = hosts.timeline;
        APPLICATION_PROTOCOL = "http";
        DATABASE_HOST = "dawarich-db";
        DATABASE_PORT = "5432";
        DATABASE_USERNAME = dawarichDbUser;
        DATABASE_NAME = dawarichDbName;
        DOMAIN = hosts.timeline;
        OIDC_CLIENT_ID = config.flake.meta.oidc-clients.dawarich.clientId;
        OIDC_ISSUER = "https://${hosts.auth}";
        OIDC_PROVIDER_NAME = "Authelia";
        OIDC_REDIRECT_URI = "https://${hosts.timeline}/users/auth/openid_connect/callback";
        OIDC_AUTO_REGISTER = true;
        PROMETHEUS_EXPORTER_ENABLED = false;
        RAILS_ENV = "production";
        RAILS_LOG_TO_STDOUT = true;
        REDIS_URL = "redis://dawarich-redis:6379";
        SELF_HOSTED = true;
        SMTP_SERVER = "smtp.resend.com";
        SMTP_PORT = "587";
        SMTP_DOMAIN = domain;
        SMTP_USERNAME = "resend";
        SMTP_FROM = "dawarich@${domain}";
        SMTP_AUTHENTICATION = "plain";
        SMTP_STARTTLS = true;
        STORE_GEODATA = true;
        TIME_ZONE = osConfig.time.timeZone;
      };

      sharedSecrets = {
        SECRET_KEY_BASE = osConfig.services.onepassword-secrets.secretPaths.dawarichSecretKeyBase;
        DATABASE_PASSWORD = osConfig.services.onepassword-secrets.secretPaths.dawarichDbPassword;
        OIDC_CLIENT_SECRET = osConfig.services.onepassword-secrets.secretPaths.dawarichOidcClientSecret;
        SMTP_PASSWORD = osConfig.services.onepassword-secrets.secretPaths.dawarichResendApiKey;
      };
    in
    {
      config = {
        services.backup.jobs.dawarich = {
          paths = [
            "${dawarichAppDir}/storage"
            "${dawarichAppDir}/public"
          ];
          schedule = "daily";
          retention = "standard";
          providers = [ "koofr" ];
          encryptionKey = osConfig.services.onepassword-secrets.secretPaths.backupDawarichEncryptionKey;
          db = {
            type = "postgresql";
            user = "dawarich";
            passwordFile = osConfig.services.onepassword-secrets.secretPaths.dawarichDbPassword;
            container = {
              type = "podman";
              name = "dawarich-db";
            };
          };
        };

        services.podman.enable = true;
        services.podman.networks.dawarich.driver = "bridge";

        services.podman.containers.dawarich-db = {
          image = "docker.io/imresamu/postgis:17-3.5-alpine";
          autoStart = true;
          userNS = "keep-id:uid=999,gid=999";
          network = [ "dawarich.network" ];
          networkAlias = [ "dawarich-db" ];
          volumes = [
            "${dawarichDataDir}/postgresql/data:/var/lib/postgresql/data"
            "${dawarichDataDir}/postgresql/wal:/var/lib/postgresql/waldir"
          ];

          environment = {
            POSTGRES_USER = dawarichDbUser;
            POSTGRES_DB = dawarichDbName;
            POSTGRES_INITDB_ARGS = "--waldir=/var/lib/postgresql/waldir --data-checksums";
          };

          secrets = {
            POSTGRES_PASSWORD = osConfig.services.onepassword-secrets.secretPaths.dawarichDbPassword;
          };

          extraConfig = {
            Container = {
              LogDriver = "journald";
              ShmSize = "1g";
              NoNewPrivileges = true;
              HealthCmd = "pg_isready -U ${dawarichDbUser} -d ${dawarichDbName} || exit 1";
              HealthInterval = "5s";
              HealthTimeout = "5s";
              HealthRetries = 5;
            };
          };
        };

        services.podman.containers.dawarich-redis = {
          image = "docker.io/library/redis:8.8.0";
          autoStart = true;
          userNS = "keep-id:uid=999,gid=999";
          network = [ "dawarich.network" ];
          networkAlias = [ "dawarich-redis" ];
          volumes = [ "${dawarichDataDir}/redis:/data" ];

          extraConfig = {
            Container = {
              LogDriver = "journald";
              NoNewPrivileges = true;
              HealthCmd = "redis-cli --raw incr ping";
              HealthInterval = "5s";
              HealthTimeout = "5s";
              HealthRetries = 5;
            };
          };
        };

        services.podman.containers.dawarich-app = {
          image = dawarichImage;
          autoStart = true;
          userNS = "keep-id:uid=1000,gid=1000";
          network = [ "dawarich.network" ];
          networkAlias = [ "dawarich-app" ];
          ports = [ "${toString reverseProxyPort}:${toString dawarichPort}" ];

          entrypoint = "web-entrypoint.sh";
          exec = "bin/rails server -p ${toString dawarichPort} -b ::";

          volumes = [
            "${dawarichAppDir}/public:/var/app/public"
            "${dawarichAppDir}/watched:/var/app/tmp/imports/watched"
            "${dawarichAppDir}/storage:/var/app/storage"
            "${dawarichDataDir}/db_data:/dawarich_db_data"
          ];

          environment = sharedEnv // {
            WEB_CONCURRENCY = "1";
          };

          secrets = sharedSecrets;

          extraConfig = {
            Unit = {
              After = [
                "podman-dawarich-db.service"
                "podman-dawarich-redis.service"
              ];
              Requires = [
                "podman-dawarich-db.service"
                "podman-dawarich-redis.service"
              ];
            };
            Container = {
              LogDriver = "journald";
              NoNewPrivileges = true;
              HealthCmd = "wget --no-verbose --tries=1 --spider http://localhost:3000/api/v1/health || exit 1";
              HealthInterval = "30s";
              HealthTimeout = "10s";
              HealthRetries = 3;
              HealthStartPeriod = "30s";
            };
          };
        };

        services.podman.containers.dawarich-sidekiq = {
          image = dawarichImage;
          autoStart = true;
          userNS = "keep-id:uid=1000,gid=1000";
          network = [ "dawarich.network" ];
          networkAlias = [ "dawarich-sidekiq" ];

          entrypoint = "sidekiq-entrypoint.sh";
          exec = "sidekiq";

          volumes = [
            "${dawarichAppDir}/public:/var/app/public"
            "${dawarichAppDir}/watched:/var/app/tmp/imports/watched"
            "${dawarichAppDir}/storage:/var/app/storage"
          ];

          environment = sharedEnv // {
            BACKGROUND_PROCESSING_CONCURRENCY = "3";
          };

          secrets = sharedSecrets;

          extraConfig = {
            Unit = {
              After = [
                "podman-dawarich-db.service"
                "podman-dawarich-redis.service"
                "podman-dawarich-app.service"
              ];
              Requires = [
                "podman-dawarich-db.service"
                "podman-dawarich-redis.service"
                "podman-dawarich-app.service"
              ];
            };
            Container = {
              LogDriver = "journald";
              NoNewPrivileges = true;
              HealthCmd = "ps aux | grep -q '[s]idekiq' || exit 1";
              HealthInterval = "30s";
              HealthTimeout = "10s";
              HealthRetries = 3;
            };
          };
        };
      };
    };
}
