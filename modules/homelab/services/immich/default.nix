{
  config,
  ...
}:
let
  immichUid = 903;
  immichGid = 903;
  immichUser = "immich";
  immichGroup = "immich";
  immichAppDir = "/var/lib/podman/immich";
  immichDataDir = "/var/lib/data/immich";

  hosts = config.flake.meta.reverse-proxy.hosts;
  reverseProxyPort = config.flake.meta.reverse-proxy.ports.immich;
  immichPort = 2283;
  immichDbUser = "postgres";
  immichDbName = "immich";
  immichOidcClientId = config.flake.meta.oidc-clients.immich.clientId;

  immichConfig = {
    storageTemplate = {
      enabled = true;
      hashVerificationEnabled = true;
      template = "{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}";
    };
  };
in
{
  flake.homepage.services.immich = {
    category = "Media";
    name = "Immich";
    description = "Photo & Video Management";
    icon = "sh-immich.webp";
    href = "http://localhost:${toString reverseProxyPort}";
    siteMonitor = "http://localhost:${toString reverseProxyPort}";
    widget = config.flake.lib.beszel.mkWidget {
      systemId = "Immich";
    };
    container = "immich-server";
    dockerServer = "immich";
    dockerSocketProxyPort = config.flake.meta.reverse-proxy.ports.immich-docker-socket-proxy;
    pingPort = reverseProxyPort;
  };

  flake.modules.nixos.homelab-immich = {
    users.users.${immichUser} = {
      uid = immichUid;
      isSystemUser = true;
      group = immichGroup;
      extraGroups = [
        "podman"
        "homelab-users"
        "rclone"
      ];
      createHome = true;
      home = "/var/lib/${immichUser}";
      autoSubUidGidRange = true;
      linger = true;
    };

    users.groups.${immichGroup} = {
      gid = immichGid;
    };

    systemd.tmpfiles.rules = [
      "d ${immichAppDir} 0750 ${immichUser} ${immichGroup} -"
      "d ${immichAppDir}/photos 0750 ${immichUser} ${immichGroup} -"
      "d ${immichDataDir} 0750 ${immichUser} ${immichGroup} -"
      "d ${immichDataDir}/postgresql 0750 ${immichUser} ${immichGroup} -"
      "d ${immichDataDir}/postgresql/data 0750 ${immichUser} ${immichGroup} -"
      "d ${immichDataDir}/postgresql/wal 0750 ${immichUser} ${immichGroup} -"
    ];

    boot.initrd.impermanence.persist.directories = [
      {
        directory = immichAppDir;
        user = immichUser;
        group = immichGroup;
        mode = "0750";
      }
    ];

    home-manager.users.${immichUser} = {
      services.rclone.remotes = [ "koofr" ];
      home.username = immichUser;
      home.stateVersion = "26.05";
      imports = with config.flake.modules.homeManager; [
        base
        backup
        homelab-immich
        podman-secrets
        homelab-beszel-agent
      ];
      services.homelab-beszel-agent = {
        enable = true;
        port = config.flake.meta.reverse-proxy.ports.beszel-agent-immich;
      };
    };

    services.onepassword-secrets.secrets = {
      immichDbPassword = {
        path = "/run/secrets/immich/db_password";
        reference = "op://Homelab/Immich/Database/password";
        owner = immichUser;
        group = immichGroup;
      };
      immichOidcClientSecret = {
        path = "/run/secrets/immich/oidc_client_secret";
        reference = "op://Homelab/Immich/Authentication/OIDC client secret";
        owner = immichUser;
        group = immichGroup;
      };
      backupImmichEncryptionKey = {
        path = "/run/secrets/immich/backup_encryption_key";
        reference = "op://Homelab/Backup/Immich/password";
        owner = immichUser;
        group = immichGroup;
      };
    };

    services.caddy.virtualHosts."${hosts.immich}" = {
      extraConfig = ''
        import reverse_proxy_common

        request_body {
          max_size 50GB
        }

        reverse_proxy localhost:${toString reverseProxyPort} {
          transport http {
            read_timeout 600s
            write_timeout 600s
          }
        }
      '';
    };
  };

  flake.modules.homeManager.homelab-immich =
    { osConfig, pkgs, ... }:
    let
      sharedEnv = {
        DB_HOSTNAME = "immich-db";
        DB_PORT = "5432";
        DB_DATABASE_NAME = immichDbName;
        DB_USERNAME = immichDbUser;
        DB_VECTOR_EXTENSION = "vectorchord";
        IMMICH_OAUTH_ENABLED = "true";
        IMMICH_OAUTH_ISSUER_URL = "https://${hosts.auth}";
        IMMICH_OAUTH_CLIENT_ID = immichOidcClientId;
        IMMICH_OAUTH_SCOPE = "openid profile email";
        IMMICH_OAUTH_AUTO_LAUNCH = "true";
        IMMICH_OAUTH_AUTO_REGISTRATION = "true";
        REDIS_HOSTNAME = "immich-redis";
        REDIS_PORT = "6379";
        TZ = osConfig.time.timeZone;
      };

      sharedSecrets = {
        DB_PASSWORD = osConfig.services.onepassword-secrets.secretPaths.immichDbPassword;
        IMMICH_OAUTH_CLIENT_SECRET =
          osConfig.services.onepassword-secrets.secretPaths.immichOidcClientSecret;
      };

      immichConfigFile = pkgs.writeText "immich-config.json" (builtins.toJSON immichConfig);
    in
    {
      config = {
        services.backup.jobs.immich = {
          paths = [
            "${immichAppDir}/photos/library"
            "${immichAppDir}/photos/upload"
            "${immichAppDir}/photos/profile"
            "${immichAppDir}/photos/backups"
          ];
          schedule = "daily";
          retention = "standard";
          providers = [ "koofr" ];
          encryptionKey = osConfig.services.onepassword-secrets.secretPaths.backupImmichEncryptionKey;
        };

        services.podman.enable = true;
        services.podman.networks.immich.driver = "bridge";

        services.podman.containers.immich-server = {
          image = "ghcr.io/immich-app/immich-server:v3.0.3";
          autoStart = true;
          userNS = "keep-id:uid=1000,gid=1000";
          capDrop = [ "NET_RAW" ];
          network = [ "immich.network" ];
          networkAlias = [ "immich-server" ];
          ports = [ "${toString reverseProxyPort}:${toString immichPort}" ];

          volumes = [
            "${immichAppDir}/photos:/data"
            "/etc/localtime:/etc/localtime:ro"
            "${immichConfigFile}:/config/immich.json:ro"
          ];

          environment = sharedEnv // {
            IMMICH_CONFIG_FILE = "/config/immich.json";
            # Set to "false" after initial admin registration to disable /auth/admin-sign-up
            IMMICH_ALLOW_SETUP = "true";
            IMMICH_TRUSTED_PROXIES = "10.89.0.0/16";
          };

          secrets = sharedSecrets;

          extraConfig = {
            Container = {
              LogDriver = "journald";
              SecurityLabelDisable = false;
              NoNewPrivileges = true;
              HealthCmd = "wget --no-verbose --tries=1 --spider http://localhost:2283/api/server/ping || exit 1";
              HealthInterval = "30s";
              HealthTimeout = "10s";
              HealthRetries = 3;
            };
          };
        };

        services.podman.containers.immich-machine-learning = {
          image = "ghcr.io/immich-app/immich-machine-learning:v3.0.3";
          autoStart = true;
          userNS = "keep-id:uid=1000,gid=1000";
          capDrop = [ "NET_RAW" ];
          network = [ "immich.network" ];
          networkAlias = [ "immich-machine-learning" ];

          volumes = [
            "${immichAppDir}/ml-models:/cache"
            "${immichAppDir}/ml-dotcache:/.cache"
            "${immichAppDir}/ml-config:/.config"
          ];

          environment = sharedEnv;

          secrets = {
            DB_PASSWORD = osConfig.services.onepassword-secrets.secretPaths.immichDbPassword;
          };

          extraConfig = {
            Container = {
              NoNewPrivileges = true;
              HealthCmd = "wget --no-verbose --tries=1 --spider http://localhost:3003/ping || exit 1";
              HealthInterval = "30s";
              HealthTimeout = "10s";
              HealthRetries = 3;
            };
          };

          services.podman.containers.immich-redis = {
            image = "docker.io/valkey/valkey:9@sha256:4963247afc4cd33c7d3b2d2816b9f7f8eeebab148d29056c2ca4d7cbc966f2d9";
            autoStart = true;
            userNS = "keep-id:uid=999,gid=999";
            capDrop = [ "NET_RAW" ];
            network = [ "immich.network" ];
            networkAlias = [ "immich-redis" ];
            volumes = [ "${immichDataDir}/redis:/data" ];

            extraConfig.Container = {
              LogDriver = "journald";
              HealthCmd = "redis-cli ping || exit 1";
              HealthInterval = "5s";
              HealthTimeout = "5s";
              HealthRetries = 5;
              NoNewPrivileges = true;
            };
          };

          services.podman.containers.immich-db = {
            image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
            autoStart = true;
            userNS = "keep-id:uid=999,gid=999";
            capDrop = [ "NET_RAW" ];
            network = [ "immich.network" ];
            networkAlias = [ "immich-db" ];
            volumes = [
              "${immichDataDir}/postgresql/data:/var/lib/postgresql/data"
              "${immichDataDir}/postgresql/wal:/var/lib/postgresql/waldir"
            ];

            environment = {
              POSTGRES_USER = immichDbUser;
              POSTGRES_DB = immichDbName;
              POSTGRES_INITDB_ARGS = "--waldir=/var/lib/postgresql/waldir --data-checksums";
            };

            secrets = {
              POSTGRES_PASSWORD = osConfig.services.onepassword-secrets.secretPaths.immichDbPassword;
            };

            extraConfig = {
              Container = {
                LogDriver = "journald";
                ShmSize = "128m";
                NoNewPrivileges = true;
                HealthCmd = "pg_isready -U ${immichDbUser} -d ${immichDbName} || exit 1";
                HealthInterval = "5s";
                HealthTimeout = "5s";
                HealthRetries = 5;
              };
            };
          };
        };
      };
    };
}
