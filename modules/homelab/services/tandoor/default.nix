{
  config,
  lib,
  ...
}:
let
  tandoorUser = "tandoor";
  tandoorGroup = "tandoor";
  tandoorAppDir = "/var/lib/containers/tandoor";
  tandoorDataDir = "/var/lib/data/tandoor";

  domain = config.flake.meta.reverse-proxy.domain;
  reverseProxyPort = config.flake.meta.reverse-proxy.ports.tandoor;
  mkHomepageLabels = config.flake.lib.mkHomepageLabels;

  tandoorImage = "ghcr.io/tandoorrecipes/recipes:latest";
  tandoorPort = 8080;
  tandoorDbName = "tandoor";
  tandoorDbUser = "tandoor";
  tandoorDbPasswordFile = "/run/secrets/tandoor/db_password";
  tandoorSecretKeyFile = "/run/secrets/tandoor/secret_key";
  tandoorOidcClientId = config.flake.meta.oidc-clients.tandoor.clientId or "";
  tandoorOidcSecretFile = "/run/secrets/tandoor/oidc_client_secret";
in
{
  flake.modules.nixos.tandoor = {
    users.users.${tandoorUser} = {
      isSystemUser = true;
      group = tandoorGroup;
      extraGroups = [ "podman" ];
      createHome = true;
      home = "/var/lib/${tandoorUser}";
      autoSubUidGidRange = true;
      linger = true;
    };

    users.groups.${tandoorGroup} = { };

    home-manager.users.${tandoorUser} = {
      home.username = tandoorUser;
      home.stateVersion = "24.11";
      imports = with config.flake.modules.homeManager; [
        base
        backup
        podman-secrets
        tandoor
      ];
    };

    services.caddy.virtualHosts."recipes.${domain}" = {
      extraConfig = ''
        import reverse_proxy_common
        reverse_proxy localhost:${toString reverseProxyPort}
      '';
    };
  };

  flake.modules.homeManager.tandoor =
    hmArgs@{ osConfig, ... }:
    let
      sharedEnv = {
        ALLOWED_HOSTS = "*";
        DB_ENGINE = "django.db.backends.postgresql";
        POSTGRES_HOST = "db";
        POSTGRES_DB = tandoorDbName;
        POSTGRES_USER = tandoorDbUser;
        TZ = osConfig.time.timeZone;
      };

      oidcEnv = lib.optionalAttrs (tandoorOidcSecretFile != null) {
        OIDC_ENDPOINT = "https://auth.${domain}";
        OIDC_CLIENT_ID = tandoorOidcClientId;
        OIDC_SCOPES = "openid,profile,email";
      };

      oidcSecrets = lib.optionalAttrs (tandoorOidcSecretFile != null) {
        OIDC_CLIENT_SECRET = tandoorOidcSecretFile;
      };
    in
    {
      config = {
        programs.onepassword-secrets.secrets = {
          tandoorSecretKey = {
            path = "/run/secrets/tandoor/secret_key";
            reference = "op://Homelab/Tandoor/Authentication/secret key";
            owner = tandoorUser;
            group = tandoorGroup;
          };
          tandoorDbPassword = {
            path = "/run/secrets/tandoor/db_password";
            reference = "op://Homelab/Tandoor/Database/password";
            owner = tandoorUser;
            group = tandoorGroup;
          };
          tandoorOidcClientSecret = {
            path = "/run/secrets/tandoor/oidc_client_secret";
            reference = "op://Homelab/Tandoor/Authentication/OIDC client secret";
            owner = tandoorUser;
            group = tandoorGroup;
          };
          backupTandoorEncryptionKey = {
            path = "/run/secrets/tandoor/backup_encryption_key";
            reference = "op://Homelab/Backup/tandoor/password";
            owner = tandoorUser;
            group = tandoorGroup;
          };
        };

        services.backup.jobs.tandoor = {
          paths = [
            "${tandoorDataDir}/postgres"
            "${tandoorAppDir}/mediafiles"
          ];
          schedule = "daily";
          retention = "standard";
          providers = [ "koofr" ];
          encryptionKey = hmArgs.config.services.onepassword-secrets.secretPaths.backupTandoorEncryptionKey;
        };

        services.podman.enable = true;
        services.podman.networks.tandoor.driver = "bridge";

        services.podman.containers.tandoor-db = {
          image = "docker.io/library/postgres:16";
          autoStart = true;
          userNS = "keep-id";
          network = [ "tandoor.network" ];
          networkAlias = [ "db" ];
          volumes = [ "${tandoorDataDir}/postgres:/var/lib/postgresql/data" ];

          environment = {
            TZ = osConfig.time.timeZone;
            POSTGRES_USER = tandoorDbUser;
            POSTGRES_DB = tandoorDbName;
          };

          secrets = {
            POSTGRES_PASSWORD = tandoorDbPasswordFile;
          };

          extraConfig.Container = {
            HealthCmd = "pg_isready -U ${tandoorDbUser} -d ${tandoorDbName}";
            HealthInterval = "5s";
            HealthTimeout = "5s";
            HealthRetries = 5;
            NoNewPrivileges = true;
          };
        };

        services.podman.containers.tandoor = {
          image = tandoorImage;
          autoStart = true;
          userNS = "keep-id";
          network = [ "tandoor.network" ];
          networkAlias = [ "app" ];
          ports = [ "${toString reverseProxyPort}:${toString tandoorPort}" ];

          labels = mkHomepageLabels {
            category = "General";
            name = "Tandoor Recipes";
            description = "Recipe Management";
            icon = "tandoor-recipes";
            href = "http://localhost:${toString reverseProxyPort}";
            widget = {
              type = "tandoor";
              url = "http://localhost:${toString reverseProxyPort}";
            };
          };

          volumes = [
            "${tandoorAppDir}/staticfiles:/opt/recipes/staticfiles"
            "${tandoorAppDir}/mediafiles:/opt/recipes/mediafiles"
          ];

          environment = sharedEnv // oidcEnv;

          secrets = {
            SECRET_KEY = tandoorSecretKeyFile;
            POSTGRES_PASSWORD = tandoorDbPasswordFile;
          }
          // oidcSecrets;

          extraConfig = {
            Unit = {
              Requires = [ "podman-tandoor-db.service" ];
              After = [ "podman-tandoor-db.service" ];
            };
            Container.NoNewPrivileges = true;
          };
        };
      };
    };
}
