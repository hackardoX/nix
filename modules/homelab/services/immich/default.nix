{ config, lib, ... }:
{
  flake.meta.immich = {
    user = "immich";
    group = "immich";
  };

  flake.modules.nixos.homelab = {
    users.users.${config.flake.meta.immich.user} = {
      isNormalUser = true;
      extraGroups = [
        config.flake.meta.immich.group
      ];
      linger = true;
    };
    users.users.postgres.extraGroups = [
      config.flake.meta.immich.group
    ];
  };

  flake.homelab.services.immich.user = config.flake.meta.immich.user;

  flake.modules.homeManager.homelab =
    hmArgs@{ osConfig, pkgs, ... }:
    let
      cfg = hmArgs.config.services.immich;
      networkName = "immich";
      storageDir = cfg.storageDir;
      dbName = "immich";
      dbUser = "postgres";

      immichConfig = {
        storageTemplate = {
          enabled = true;
          hashVerificationEnabled = true;
          template = "{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}";
        };
      };

      immichConfigFile = pkgs.writeText "immich-config.json" (builtins.toJSON immichConfig);

      sharedEnv = {
        DB_HOSTNAME = "immich-db";
        DB_PORT = "5432";
        DB_DATABASE_NAME = dbName;
        DB_USERNAME = dbUser;
        REDIS_HOSTNAME = "immich-redis";
        REDIS_PORT = "6379";
        TZ = osConfig.time.timeZone;
      };
    in
    {
      options.services.immich = {
        enable = lib.mkEnableOption "Immich (Podman)";

        port = lib.mkOption {
          type = lib.types.port;
          default = 2283;
          description = "Host port to expose Immich on";
        };

        storageDir = lib.mkOption {
          type = lib.types.path;
          default = "/var/lib/containers/immich";
          description = "Base directory for Immich persistent data (photos, database, ML models)";
        };

        dbPasswordFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to file containing the Postgres password";
        };

        oauthClientSecretFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Path to file containing the OIDC client secret";
        };
      };

      config = lib.mkIf cfg.enable {
        services.podman.networks.${networkName}.driver = "bridge";

        services.podman.containers = {
          immich-server = {
            image = "ghcr.io/immich-app/immich-server:release";
            autoStart = true;
            userNS = "keep-id";
            network = [ "${networkName}.network" ];
            networkAlias = [ "immich-server" ];
            ports = [ "${toString cfg.port}:2283" ];

            monitoring.enable = true;

            labels = config.flake.lib.mkHomepageLabels {
              category = "Media";
              name = "Immich";
              description = "Photo & Video Management";
              icon = "immich.png";
              href = "http://localhost:${toString cfg.port}";
              widget = {
                type = "immich";
                url = "http://localhost:${toString cfg.port}";
              };
            };

            volumes = [
              "${storageDir}/photos:/data"
              "/etc/localtime:/etc/localtime:ro"
              "${immichConfigFile}:/config/immich.json:ro"
            ];

            environment =
              sharedEnv
              // {
                IMMICH_CONFIG_FILE = "/config/immich.json";
              }
              // lib.optionalAttrs (cfg.oauthClientSecretFile != null) {
                IMMICH_OAUTH_ENABLED = "true";
                IMMICH_OAUTH_ISSUER_URL = "https://auth.${config.flake.meta.reverse-proxy.domain}";
                IMMICH_OAUTH_CLIENT_ID = config.flake.meta.oidc-clients.immich.clientId;
                IMMICH_OAUTH_SCOPE = "openid profile email";
                IMMICH_OAUTH_AUTO_LAUNCH = "true";
                IMMICH_OAUTH_AUTO_REGISTRATION = "true";
              };

            secrets = {
              DB_PASSWORD = cfg.dbPasswordFile;
            }
            // lib.optionalAttrs (cfg.oauthClientSecretFile != null) {
              IMMICH_OAUTH_CLIENT_SECRET = cfg.oauthClientSecretFile;
            };

            extraConfig = {
              Unit = {
                Requires = [
                  "podman-immich-db.service"
                  "podman-immich-redis.service"
                ];
                After = [
                  "podman-immich-db.service"
                  "podman-immich-redis.service"
                ];
              };
              Container = {
                SecurityLabelDisable = false;
                NoNewPrivileges = true;
              };
            };
          };

          immich-machine-learning = {
            image = "ghcr.io/immich-app/immich-machine-learning:release";
            autoStart = true;
            userNS = "keep-id";
            network = [ "${networkName}.network" ];
            networkAlias = [ "immich-machine-learning" ];

            monitoring.enable = true;

            volumes = [
              "${storageDir}/ml-models:/cache"
              "${storageDir}/ml-dotcache:/.cache"
              "${storageDir}/ml-config:/.config"
            ];

            environment = sharedEnv;

            secrets = {
              DB_PASSWORD = cfg.dbPasswordFile;
            };

            extraConfig.Container.NoNewPrivileges = true;
          };

          immich-redis = {
            image = "docker.io/valkey/valkey:9@sha256:8436e10bc65c94886a91d4415b6a6dfa9cb5a306fb3b996e5bb67cd2b4854193";
            autoStart = true;
            userNS = "keep-id";
            network = [ "${networkName}.network" ];
            networkAlias = [ "immich-redis" ];
            volumes = [ "${storageDir}/redis:/data" ];

            monitoring.enable = true;

            extraConfig.Container = {
              HealthCmd = "redis-cli ping || exit 1";
              HealthInterval = "5s";
              HealthTimeout = "5s";
              HealthRetries = 5;
              NoNewPrivileges = true;
            };
          };

          immich-db = {
            image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
            autoStart = true;
            userNS = "keep-id";
            network = [ "${networkName}.network" ];
            networkAlias = [ "immich-db" ];
            volumes = [ "${storageDir}/postgres:/var/lib/postgresql/data" ];

            monitoring.enable = true;

            environment = {
              POSTGRES_USER = dbUser;
              POSTGRES_DB = dbName;
              POSTGRES_INITDB_ARGS = "--data-checksums";
            };

            secrets = {
              POSTGRES_PASSWORD = cfg.dbPasswordFile;
            };

            extraConfig = {
              Container = {
                ShmSize = "128m";
                NoNewPrivileges = true;
                HealthCmd = "pg_isready -U ${dbUser} -d ${dbName} || exit 1";
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
