{ lib, config, ... }:
let
  cfg = config.services.sure-finance;
  networkName = "sure-finance";
  sharedEnv = {
    POSTGRES_USER = cfg.database.user;
    POSTGRES_DB = cfg.database.name;
    SELF_HOSTED = "true";
    RAILS_FORCE_SSL = "false";
    RAILS_ASSUME_SSL = "false";
    DB_HOST = "db";
    DB_PORT = "5432";
    REDIS_URL = "redis://redis:6379/1";
  };
  sharedSecrets = {
    POSTGRES_PASSWORD = cfg.database.passwordFile;
    SECRET_KEY_BASE = cfg.secretKeyBaseFile;
  }
  // lib.optionalAttrs (cfg.openaiTokenFile != null) {
    OPENAI_ACCESS_TOKEN = cfg.openaiTokenFile;
  };
in
{
  flake.meta.sure-finance = {
    user = "sure-finance";
    group = "sure-finance";
  };

  flake.modules.nixos.homelab = {
    users.users.${config.flake.meta.sure-finance.user} = {
      isNormalUser = true;
      extraGroups = [
        config.flake.meta.sure-finance.group
      ];
    };
  };

  flake.modules.homeManager.homelab = {
    options.services.sure-finance = {
      enable = lib.mkEnableOption "Sure Finance";

      image = lib.mkOption {
        type = lib.types.str;
        default = "ghcr.io/we-promise/sure:stable";
        description = "Docker image to use for Sure Finance";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 3000;
        description = "Host port to expose Sure Finance on";
      };

      storageDir = lib.mkOption {
        type = lib.types.path;
        default = "${config.home.homeDirectory}/containers/sure-finance";
        defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/containers/sure-finance"'';
        description = "Base directory for Sure Finance persistent data";
      };

      database = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "sure_production";
          description = "Postgres database name";
        };
        user = lib.mkOption {
          type = lib.types.str;
          default = "sure_user";
          description = "Postgres database user";
        };
        passwordFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to file containing the Postgres password";
        };
      };

      secretKeyBaseFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to file containing the Rails SECRET_KEY_BASE";
      };

      openaiTokenFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to file containing the OpenAI API token. If null, AI features are disabled.";
      };
    };

    config = lib.mkIf cfg.enable {
      services.podman.networks.${networkName} = {
        driver = "bridge";
      };

      services.podman.containers = {
        sure-finance-db = {
          image = "docker.io/library/postgres:16";
          autoStart = true;
          network = [ "${networkName}.network" ];
          networkAlias = [ "db" ];
          volumes = [ "${cfg.storageDir}/postgres:/var/lib/postgresql/data" ];

          environment = {
            POSTGRES_USER = cfg.database.user;
            POSTGRES_DB = cfg.database.name;
          };

          secrets = {
            POSTGRES_PASSWORD = cfg.database.passwordFile;
          };

          extraConfig.Container = {
            HealthCmd = "pg_isready -U ${cfg.database.user} -d ${cfg.database.name}";
            HealthInterval = "5s";
            HealthTimeout = "5s";
            HealthRetries = 5;
          };
        };

        sure-finance-redis = {
          image = "docker.io/library/redis:latest";
          autoStart = true;
          network = [ "${networkName}.network" ];
          networkAlias = [ "redis" ];
          volumes = [ "${cfg.storageDir}/redis:/data" ];

          extraConfig.Container = {
            HealthCmd = "redis-cli ping";
            HealthInterval = "5s";
            HealthTimeout = "5s";
            HealthRetries = 5;
          };
        };

        sure-finance-web = {
          image = cfg.image;
          autoStart = true;
          network = [ "${networkName}.network" ];
          networkAlias = [ "web" ];
          volumes = [ "${cfg.storageDir}/storage:/rails/storage" ];
          ports = [ "${toString cfg.port}:3000" ];

          environment = sharedEnv;
          secrets = sharedSecrets;

          extraConfig = {
            Unit = {
              Requires = [
                "podman-sure-finance-db.service"
                "podman-sure-finance-redis.service"
              ];
              After = [
                "podman-sure-finance-db.service"
                "podman-sure-finance-redis.service"
              ];
            };
            Container.DNS = [
              "8.8.8.8"
              "1.1.1.1"
            ];
          };
        };

        sure-finance-worker = {
          image = cfg.image;
          autoStart = true;
          network = [ "${networkName}.network" ];
          networkAlias = [ "worker" ];
          volumes = [ "${cfg.storageDir}/storage:/rails/storage" ];

          exec = "bundle exec sidekiq";

          environment = sharedEnv;
          secrets = sharedSecrets;

          extraConfig = {
            Unit = {
              Requires = [
                "podman-sure-finance-db.service"
                "podman-sure-finance-redis.service"
              ];
              After = [
                "podman-sure-finance-db.service"
                "podman-sure-finance-redis.service"
              ];
            };
            Container.DNS = [
              "8.8.8.8"
              "1.1.1.1"
            ];
          };
        };
      };
    };
  };
}
