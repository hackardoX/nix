{ lib, config, ... }:
{
  flake.meta.tandoor = {
    user = "tandoor";
    group = "tandoor";
  };

  flake.modules.nixos.homelab = {
    users.users.${config.flake.meta.tandoor.user} = {
      isNormalUser = true;
      extraGroups = [
        config.flake.meta.tandoor.group
      ];
      linger = true;
    };
  };

  flake.homelab.services.tandoor.user = config.flake.meta.tandoor.user;

  flake.modules.homeManager.homelab =
    hmArgs@{ osConfig, ... }:
    let
      cfg = hmArgs.config.services.tandoor;
      networkName = "tandoor";
      sharedEnv = {
        ALLOWED_HOSTS = "*";
        DB_ENGINE = "django.db.backends.postgresql";
        POSTGRES_HOST = "db";
        POSTGRES_DB = cfg.database.name;
        POSTGRES_USER = cfg.database.user;
        TZ = osConfig.time.timeZone;
      };
    in
    {
      options.services.tandoor = {
        enable = lib.mkEnableOption "Tandoor Recipes";

        image = lib.mkOption {
          type = lib.types.str;
          default = "ghcr.io/tandoorrecipes/recipes:latest";
          description = "Docker image to use for Tandoor";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 8080;
          description = "Host port to expose Tandoor on";
        };

        storageDir = lib.mkOption {
          type = lib.types.path;
          default = "/var/lib/containers/tandoor";
          description = "Base directory for Tandoor persistent data";
        };

        secretKeyFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to file containing the Django SECRET_KEY";
        };

        database = {
          name = lib.mkOption {
            type = lib.types.str;
            default = "tandoor";
            description = "PostgreSQL database name";
          };

          user = lib.mkOption {
            type = lib.types.str;
            default = "tandoor";
            description = "PostgreSQL database user";
          };

          passwordFile = lib.mkOption {
            type = lib.types.path;
            description = "Path to file containing the PostgreSQL password";
          };
        };

        oidcClientSecretFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Path to file containing the OIDC client secret";
        };
      };

      config = lib.mkIf cfg.enable {
        services.podman.networks.${networkName} = {
          driver = "bridge";
        };

        services.podman.containers = {
          tandoor-db = {
            image = "docker.io/library/postgres:16";
            autoStart = true;
            userNS = "keep-id";
            network = [ "${networkName}.network" ];
            networkAlias = [ "db" ];
            volumes = [ "${cfg.storageDir}/postgres:/var/lib/postgresql/data" ];

            monitoring.enable = true;

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
              NoNewPrivileges = true;
            };
          };

          tandoor = {
            image = cfg.image;
            autoStart = true;
            userNS = "keep-id";
            network = [ "${networkName}.network" ];
            networkAlias = [ "app" ];
            ports = [ "${toString cfg.port}:8080" ];

            monitoring.enable = true;

            labels = config.flake.lib.mkHomepageLabels {
              category = "General";
              name = "Tandoor Recipes";
              description = "Recipe Management";
              icon = "tandoor-recipes";
              href = "http://localhost:${toString cfg.port}";
              widget = {
                type = "tandoor";
                url = "http://localhost:${toString cfg.port}";
              };
            };

            volumes = [
              "${cfg.storageDir}/staticfiles:/opt/recipes/staticfiles"
              "${cfg.storageDir}/mediafiles:/opt/recipes/mediafiles"
            ];

            environment =
              sharedEnv
              // lib.optionalAttrs (cfg.oidcClientSecretFile != null) {
                OIDC_ENDPOINT = "https://auth.${config.flake.meta.reverse-proxy.domain}";
                OIDC_CLIENT_ID = config.flake.meta.oidc-clients.tandoor.clientId;
                OIDC_SCOPES = "openid,profile,email";
              };

            secrets = {
              SECRET_KEY = cfg.secretKeyFile;
              POSTGRES_PASSWORD = cfg.database.passwordFile;
            }
            // lib.optionalAttrs (cfg.oidcClientSecretFile != null) {
              OIDC_CLIENT_SECRET = cfg.oidcClientSecretFile;
            };

            extraConfig = {
              Unit = {
                Requires = [ "podman-tandoor-db.service" ];
                After = [ "podman-tandoor-db.service" ];
              };
              Container = {
                NoNewPrivileges = true;
              };
            };
          };
        };
      };
    };
}
