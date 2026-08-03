{
  config,
  lib,
  ...
}:
let
  tandoorUid = 904;
  tandoorGid = 904;
  tandoorUser = "tandoor";
  tandoorGroup = "tandoor";
  tandoorAppDir = "/var/lib/podman/tandoor";
  tandoorDataDir = "/var/lib/data/tandoor";

  hosts = config.flake.meta.reverse-proxy.hosts;
  reverseProxyPort = config.flake.meta.reverse-proxy.ports.tandoor;
  tandoorImage = "ghcr.io/tandoorrecipes/recipes:2.6.13";
  tandoorPort = 80;
  tandoorDbName = "tandoor";
  tandoorDbUser = "tandoor";
  tandoorOidcClientId = config.flake.meta.oidc-clients.tandoor.clientId;
in
{
  flake.homepage.services.tandoor = {
    category = "General";
    name = "Tandoor Recipes";
    description = "Recipe Management";
    icon = "sh-tandoor-recipes.webp";
    href = "https://${hosts.recipes}";
    siteMonitor = "http://localhost:${toString reverseProxyPort}/api/health";
    widget = config.flake.lib.beszel.mkWidget {
      systemId = "Tandoor";
    };
    container = "tandoor";
    dockerServer = "tandoor";
    dockerSocketProxyPort = config.flake.meta.reverse-proxy.ports.homepage-docker-socket-proxy;
    pingPort = reverseProxyPort;
  };

  flake.modules.nixos.homelab-tandoor = {
    users.users.${tandoorUser} = {
      uid = tandoorUid;
      isSystemUser = true;
      group = tandoorGroup;
      extraGroups = [
        "podman"
        "homelab-users"
        "rclone"
      ];
      createHome = true;
      home = "/var/lib/${tandoorUser}";
      autoSubUidGidRange = true;
      linger = true;
    };

    users.groups.${tandoorGroup} = {
      gid = tandoorGid;
    };

    systemd.tmpfiles.rules = [
      "d ${tandoorAppDir} 0750 ${tandoorUser} ${tandoorGroup} -"
      "d ${tandoorAppDir}/staticfiles 0750 ${tandoorUser} ${tandoorGroup} -"
      "d ${tandoorAppDir}/mediafiles 0750 ${tandoorUser} ${tandoorGroup} -"
      "d ${tandoorDataDir} 0750 ${tandoorUser} ${tandoorGroup} -"
      "d ${tandoorDataDir}/postgresql 0750 ${tandoorUser} ${tandoorGroup} -"
      "d ${tandoorDataDir}/postgresql/data 0750 ${tandoorUser} ${tandoorGroup} -"
      "d ${tandoorDataDir}/postgresql/wal 0750 ${tandoorUser} ${tandoorGroup} -"
    ];

    boot.initrd.impermanence.persist.directories = [
      {
        directory = tandoorAppDir;
        user = tandoorUser;
        group = tandoorGroup;
        mode = "0750";
      }
    ];

    home-manager.users.${tandoorUser} = {
      imports = with config.flake.modules.homeManager; [
        base
        backup
        podman-secrets
        homelab-beszel-agent
        homelab-docker-socket-proxy
        homelab-tandoor
      ];
      home.username = tandoorUser;
      home.stateVersion = "26.05";
      services.homelab-beszel-agent = {
        enable = true;
        port = config.flake.meta.reverse-proxy.ports.beszel-agent-tandoor;
      };
      services.homelab-docker-socket-proxy = {
        enable = true;
        port = config.flake.meta.reverse-proxy.ports.homepage-docker-socket-proxy;
      };
      services.rclone.remotes = [ "koofr" ];
    };

    services.onepassword-secrets.secrets = {
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
        reference = "op://Homelab/Backup/Tandoor/password";
        owner = tandoorUser;
        group = tandoorGroup;
      };
    };

    services.caddy.virtualHosts."${hosts.recipes}" = {
      extraConfig = ''
        import reverse_proxy_common
        reverse_proxy localhost:${toString reverseProxyPort}
      '';
    };
  };

  flake.modules.homeManager.homelab-tandoor =
    { osConfig, ... }:
    let
      sharedEnv = {
        ALLOWED_HOSTS = "localhost,${hosts.recipes}";
        DB_ENGINE = "django.db.backends.postgresql";
        POSTGRES_HOST = "db";
        POSTGRES_DB = tandoorDbName;
        POSTGRES_USER = tandoorDbUser;
        TZ = osConfig.time.timeZone;
      };

      oidcEnv =
        lib.optionalAttrs (osConfig.services.onepassword-secrets.secretPaths ? tandoorOidcClientSecret)
          {
            OIDC_ENDPOINT = "https://${hosts.auth}";
            OIDC_CLIENT_ID = tandoorOidcClientId;
            OIDC_SCOPES = "openid,profile,email";
          };

      oidcSecrets =
        lib.optionalAttrs (osConfig.services.onepassword-secrets.secretPaths ? tandoorOidcClientSecret)
          {
            OIDC_CLIENT_SECRET = osConfig.services.onepassword-secrets.secretPaths.tandoorOidcClientSecret;
          };
    in
    {
      config = {
        services.backup.jobs.tandoor = {
          paths = [
            "${tandoorDataDir}/postgresql/data"
            "${tandoorAppDir}/mediafiles"
          ];
          schedule = "daily";
          retention = "standard";
          providers = [ "koofr" ];
          encryptionKey = osConfig.services.onepassword-secrets.secretPaths.backupTandoorEncryptionKey;
        };

        services.podman.enable = true;
        services.podman.networks.tandoor.driver = "bridge";

        services.podman.containers.tandoor-db = {
          image = "docker.io/library/postgres:16.14";
          autoStart = true;
          userNS = "keep-id:uid=999,gid=999";
          network = [ "tandoor.network" ];
          networkAlias = [ "db" ];
          volumes = [
            "${tandoorDataDir}/postgresql/data:/var/lib/postgresql/data"
            "${tandoorDataDir}/postgresql/wal:/var/lib/postgresql/waldir"
          ];

          environment = {
            TZ = osConfig.time.timeZone;
            POSTGRES_USER = tandoorDbUser;
            POSTGRES_DB = tandoorDbName;
            POSTGRES_INITDB_ARGS = "--waldir=/var/lib/postgresql/waldir --data-checksums";
          };

          secrets = {
            POSTGRES_PASSWORD = osConfig.services.onepassword-secrets.secretPaths.tandoorDbPassword;
          };

          extraConfig = {
            Container = {
              LogDriver = "journald";
              HealthCmd = "pg_isready -U ${tandoorDbUser} -d ${tandoorDbName}";
              HealthInterval = "5s";
              HealthTimeout = "5s";
              HealthRetries = 5;
              NoNewPrivileges = true;
            };
          };
        };

        services.podman.containers.tandoor = {
          image = tandoorImage;
          autoStart = true;
          userNS = "keep-id:uid=0,gid=0";
          network = [ "tandoor.network" ];
          networkAlias = [ "app" ];
          ports = [ "${toString reverseProxyPort}:${toString tandoorPort}" ];

          volumes = [
            "${tandoorAppDir}/staticfiles:/opt/recipes/staticfiles"
            "${tandoorAppDir}/mediafiles:/opt/recipes/mediafiles"
          ];

          environment = sharedEnv // oidcEnv;

          secrets = {
            SECRET_KEY = osConfig.services.onepassword-secrets.secretPaths.tandoorSecretKey;
            POSTGRES_PASSWORD = osConfig.services.onepassword-secrets.secretPaths.tandoorDbPassword;
          }
          // oidcSecrets;

          extraConfig = {
            Unit = {
              After = [ "podman-tandoor-db.service" ];
              Requires = [ "podman-tandoor-db.service" ];
            };
            Container = {
              NoNewPrivileges = true;
              HealthCmd = "curl -sf http://localhost:${toString tandoorPort}/api/health || exit 1";
              HealthInterval = "30s";
              HealthTimeout = "10s";
              HealthRetries = 3;
            };
          };
        };
      };
    };
}
