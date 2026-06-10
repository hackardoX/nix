{ lib, config, ... }:
{
  flake.meta.reactive-resume = {
    user = "reactive-resume";
    group = "reactive-resume";
  };

  flake.modules.nixos.homelab = {
    users.users.${config.flake.meta.reactive-resume.user} = {
      isNormalUser = true;
      extraGroups = [
        config.flake.meta.reactive-resume.group
      ];
    };
  };

  flake.modules.homeManager."${config.flake.meta.reactive-resume.user}@homelab" =
    hmArgs@{ osConfig, pkgs, ... }:
    let
      cfg = hmArgs.config.services.reactive-resume;
      networkName = "reactive-resume";
      entrypointScript = pkgs.writeShellScript "reactive-resume-entrypoint" ''
        DB_PASSWORD=$(cat /run/secrets/DATABASE_PASSWORD)
        export DATABASE_URL="postgresql://${cfg.database.user}:''${DB_PASSWORD}@db:5432/${cfg.database.name}"
        exec "$@"
      '';
    in
    {
      options.services.reactive-resume = {
        enable = lib.mkEnableOption "Reactive Resume";

        image = lib.mkOption {
          type = lib.types.str;
          default = "amruthpillai/reactive-resume:latest";
          description = "Docker image to use for Reactive Resume";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 3000;
          description = "Host port to expose Reactive Resume on";
        };

        storageDir = lib.mkOption {
          type = lib.types.path;
          default = "${config.home.homeDirectory}/containers/reactive-resume";
          defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/containers/reactive-resume"'';
          description = "Base directory for Reactive Resume persistent data";
        };

        appUrl = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          description = "Public URL for Reactive Resume.";
        };

        authSecretFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to file containing the AUTH_SECRET for session encryption";
        };

        database = {
          name = lib.mkOption {
            type = lib.types.str;
            default = "rxresume";
            description = "PostgreSQL database name";
          };

          user = lib.mkOption {
            type = lib.types.str;
            default = "rxresume";
            description = "PostgreSQL database user";
          };

          passwordFile = lib.mkOption {
            type = lib.types.path;
            description = "Path to file containing the PostgreSQL password";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        services.podman.networks.${networkName} = {
          driver = "bridge";
        };

        services.podman.containers = {
          reactive-resume-db = {
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

          reactive-resume = {
            image = cfg.image;
            autoStart = true;
            userNS = "keep-id";
            network = [ "${networkName}.network" ];
            networkAlias = [ "app" ];
            ports = [ "${toString cfg.port}:3000" ];

            monitoring.enable = true;

            volumes = [
              "${entrypointScript}:/entrypoint.sh:ro"
            ];

            environment = {
              TZ = osConfig.time.timeZone;
              APP_URL = cfg.appUrl;
              FLAG_DISABLE_SIGNUPS = "true";
              FLAG_DISABLE_EMAIL_AUTH = "false";
              FLAG_DISABLE_IMAGE_PROCESSING = "false";
            };

            secrets = {
              AUTH_SECRET = cfg.authSecretFile;
              DATABASE_PASSWORD = cfg.database.passwordFile;
            };

            extraConfig = {
              Unit = {
                Requires = [ "podman-reactive-resume-db.service" ];
                After = [ "podman-reactive-resume-db.service" ];
              };
              Container = {
                Entrypoint = [ "/entrypoint.sh" ];
                Cmd = [
                  "node"
                  "dist/apps/server/main.js"
                ];
                HealthCmd = "node -e \"fetch('http://127.0.0.1:3000/api/health').then((r) => { if (!r.ok) process.exit(1); }).catch(() => process.exit(1));\"";
                HealthInterval = "30s";
                HealthTimeout = "10s";
                HealthRetries = 3;
                StartPeriod = "30s";
                NoNewPrivileges = true;
              };
            };
          };
        };
      };
    };
}
