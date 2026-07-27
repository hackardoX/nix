{
  config,
  lib,
  ...
}:
let
  immichUid = 903;
  immichGid = 903;
  immichUser = "immich";
  immichGroup = "immich";
  immichAppDir = "/var/lib/containers/immich";
  immichDataDir = "/var/lib/data/immich";

  domain = config.flake.meta.reverse-proxy.domain;
  hosts = config.flake.meta.reverse-proxy.hosts;
  reverseProxyPort = config.flake.meta.reverse-proxy.ports.immich;
  mkHomepageLabels = config.flake.lib.mkHomepageLabels;

  immichPort = 2283;
  immichDbUser = "postgres";
  immichDbName = "immich";
  immichDbPasswordFile = "/run/secrets/immich/db_password";
  immichOidcClientId = config.flake.meta.oidc-clients.immich.clientId or "";
  immichOidcSecretFile = "/run/secrets/immich/oidc_client_secret";

  immichConfig = {
    storageTemplate = {
      enabled = true;
      hashVerificationEnabled = true;
      template = "{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}";
    };
  };
in
{
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
      "d ${immichDataDir}/postgres 0750 ${immichUser} ${immichGroup} -"
      "d ${immichAppDir}/containers 0750 ${immichUser} ${immichGroup} -"
    ];

    systemd.services."home-manager-${immichUser}" = {
      after = [ "user@${toString immichUid}.service" ];
      wants = [ "user@${toString immichUid}.service" ];
    };

    boot.initrd.impermanence.persist.directories = [
      {
        directory = immichAppDir;
        user = immichUser;
        group = immichGroup;
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
      ];
    };

    services.onepassword-secrets.secrets = {
      immichDbPassword = {
        path = "/run/secrets/immich/db_password";
        reference = "op://Homelab/Immich/Database/password";
        owner = immichUser;
        group = immichGroup;
        services = [
          "podman-immich-server.service"
          "podman-immich-machine-learning.service"
          "podman-immich-db.service"
        ];
      };
      immichOidcClientSecret = {
        path = "/run/secrets/immich/oidc_client_secret";
        reference = "op://Homelab/Immich/Authentication/OIDC client secret";
        owner = immichUser;
        group = immichGroup;
        services = [ "podman-immich-server.service" ];
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
        REDIS_HOSTNAME = "immich-redis";
        REDIS_PORT = "6379";
        TZ = osConfig.time.timeZone;
      };

      immichConfigFile = pkgs.writeText "immich-config.json" (builtins.toJSON immichConfig);

      oidcEnv = lib.optionalAttrs (immichOidcSecretFile != null) {
        IMMICH_OAUTH_ENABLED = "true";
        IMMICH_OAUTH_ISSUER_URL = "https://${hosts.auth}";
        IMMICH_OAUTH_CLIENT_ID = immichOidcClientId;
        IMMICH_OAUTH_SCOPE = "openid profile email";
        IMMICH_OAUTH_AUTO_LAUNCH = "true";
        IMMICH_OAUTH_AUTO_REGISTRATION = "true";
      };

      oidcSecrets = lib.optionalAttrs (immichOidcSecretFile != null) {
        IMMICH_OAUTH_CLIENT_SECRET = immichOidcSecretFile;
      };
    in
    {
      config = {
        xdg.configFile."containers/storage.conf".text = ''
          [storage]
          graphroot = "${immichAppDir}/containers"
        '';

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
          image = "ghcr.io/immich-app/immich-server:release";
          autoStart = true;
          userNS = "keep-id";
          user = "%U";
          group = "%G";
          network = [ "immich.network" ];
          networkAlias = [ "immich-server" ];
          ports = [ "${toString reverseProxyPort}:${toString immichPort}" ];

          labels = mkHomepageLabels {
            category = "Media";
            name = "Immich";
            description = "Photo & Video Management";
            icon = "immich.png";
            href = "http://localhost:${toString reverseProxyPort}";
            widget = {
              type = "immich";
              url = "http://localhost:${toString reverseProxyPort}";
            };
          };

          volumes = [
            "${immichAppDir}/photos:/data"
            "/etc/localtime:/etc/localtime:ro"
            "${immichConfigFile}:/config/immich.json:ro"
          ];

          environment =
            sharedEnv
            // {
              IMMICH_CONFIG_FILE = "/config/immich.json";
            }
            // oidcEnv;

          secrets = {
            DB_PASSWORD = immichDbPasswordFile;
          }
          // oidcSecrets;

          extraConfig = {
            Unit = {
              Wants = [ "opnix-secrets.service" ];
              After = [ "opnix-secrets.service" ];
            };
            Container = {
              LogDriver = "journald";
              SecurityLabelDisable = false;
              NoNewPrivileges = true;
            };
          };
        };

        services.podman.containers.immich-machine-learning = {
          image = "ghcr.io/immich-app/immich-machine-learning:release";
          autoStart = true;
          userNS = "keep-id";
          user = "%U";
          group = "%G";
          network = [ "immich.network" ];
          networkAlias = [ "immich-machine-learning" ];

          volumes = [
            "${immichAppDir}/ml-models:/cache"
            "${immichAppDir}/ml-dotcache:/.cache"
            "${immichAppDir}/ml-config:/.config"
          ];

          environment = sharedEnv;

          secrets = {
            DB_PASSWORD = immichDbPasswordFile;
          };

          extraConfig = {
            Unit = {
              Wants = [ "opnix-secrets.service" ];
              After = [ "opnix-secrets.service" ];
            };
            Container.NoNewPrivileges = true;
          };

          services.podman.containers.immich-redis = {
            image = "docker.io/valkey/valkey:9@sha256:8436e10bc65c94886a91d4415b6a6dfa9cb5a306fb3b996e5bb67cd2b4854193";
            autoStart = true;
            userNS = "keep-id";
            user = "%U";
            group = "%G";
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
            userNS = "keep-id";
            user = "%U";
            group = "%G";
            network = [ "immich.network" ];
            networkAlias = [ "immich-db" ];
            volumes = [ "${immichDataDir}/postgres:/var/lib/postgresql/data" ];

            environment = {
              POSTGRES_USER = immichDbUser;
              POSTGRES_DB = immichDbName;
              POSTGRES_INITDB_ARGS = "--data-checksums";
            };

            secrets = {
              POSTGRES_PASSWORD = immichDbPasswordFile;
            };

            extraConfig = {
              Unit = {
                Wants = [ "opnix-secrets.service" ];
                After = [ "opnix-secrets.service" ];
              };
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
