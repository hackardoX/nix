{ lib, config, ... }:
let
  cfg = config.services.immich-podman;
  networkName = "immich";
  storageDir = cfg.storageDir;
  dbName = "immich";
  dbUser = "postgres";
in
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
    };
    users.users.postgres.extraGroups = [
      config.flake.meta.immich.group
    ];
  };

  flake.modules.homeManager."${config.flake.meta.immich.user}@homelab" = hmArgs: {
    options.services.immich-podman = {
      enable = lib.mkEnableOption "Immich (Podman)";

      port = lib.mkOption {
        type = lib.types.port;
        default = 2283;
        description = "Host port to expose Immich on";
      };

      storageDir = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/immich";
        description = "Base directory for Immich persistent data (photos, database, ML models)";
      };

      dbPasswordFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to file containing the Postgres password";
      };
    };

    config = lib.mkIf cfg.enable {
      services.podman.networks.${networkName}.driver = "bridge";

      services.podman.containers = {
        immich-server = {
          image = "ghcr.io/immich-app/immich-server:release";
          autoStart = true;
          network = [ "${networkName}.network" ];
          networkAlias = [ "immich-server" ];
          ports = [ "${toString cfg.port}:2283" ];

          volumes = [
            "${storageDir}/photos:/data"
            "/etc/localtime:/etc/localtime:ro"
          ];

          environment = {
            DB_HOSTNAME = "immich-db";
            DB_PORT = "5432";
            DB_DATABASE_NAME = dbName;
            DB_USERNAME = dbUser;
            REDIS_HOSTNAME = "immich-redis";
            REDIS_PORT = "6379";
          };

          secrets = {
            DB_PASSWORD = cfg.dbPasswordFile;
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
          network = [ "${networkName}.network" ];
          networkAlias = [ "immich-machine-learning" ];

          volumes = [
            "${storageDir}/ml-models:/cache"
            "${storageDir}/ml-dotcache:/.cache"
            "${storageDir}/ml-config:/.config"
          ];

          environment = {
            DB_HOSTNAME = "immich-db";
            DB_PORT = "5432";
            DB_DATABASE_NAME = dbName;
            DB_USERNAME = dbUser;
            REDIS_HOSTNAME = "immich-redis";
          };

          secrets = {
            DB_PASSWORD = cfg.dbPasswordFile;
          };

          extraConfig.Container.NoNewPrivileges = true;
        };

        immich-redis = {
          image = "docker.io/valkey/valkey:9@sha256:8436e10bc65c94886a91d4415b6a6dfa9cb5a306fb3b996e5bb67cd2b4854193";
          autoStart = true;
          network = [ "${networkName}.network" ];
          networkAlias = [ "immich-redis" ];
          volumes = [ "${storageDir}/redis:/data" ];

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
          network = [ "${networkName}.network" ];
          networkAlias = [ "immich-db" ];
          volumes = [ "${storageDir}/postgres:/var/lib/postgresql/data" ];

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
