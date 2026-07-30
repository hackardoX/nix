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
  tandoorAppDir = "/var/lib/containers/tandoor";
  tandoorDataDir = "/var/lib/data/tandoor";

  hosts = config.flake.meta.reverse-proxy.hosts;
  reverseProxyPort = config.flake.meta.reverse-proxy.ports.tandoor;
  tandoorImage = "ghcr.io/tandoorrecipes/recipes:2.6.13";
  tandoorPort = 8080;
  tandoorDbName = "tandoor";
  tandoorDbUser = "tandoor";
  tandoorDbPasswordFile = "/run/secrets/tandoor/db_password";
  tandoorSecretKeyFile = "/run/secrets/tandoor/secret_key";
  tandoorOidcClientId = config.flake.meta.oidc-clients.tandoor.clientId or "";
  tandoorOidcSecretFile = "/run/secrets/tandoor/oidc_client_secret";
in
{
  flake.homepage.services.tandoor = {
    category = "General";
    name = "Tandoor Recipes";
    description = "Recipe Management";
    icon = "tandoor-recipes";
    href = "http://localhost:${toString reverseProxyPort}";
    widget = {
      type = "tandoor";
      url = "http://localhost:${toString reverseProxyPort}";
    };
    container = "tandoor";
    dockerServer = "tandoor";
    dockerSocketProxyPort = config.flake.meta.reverse-proxy.ports.tandoor-docker-socket-proxy;
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
      "d ${tandoorDataDir}/postgres 0750 ${tandoorUser} ${tandoorGroup} -"
      "d ${tandoorAppDir}/containers 0750 ${tandoorUser} ${tandoorGroup} -"
    ];

    systemd.services."home-manager-${tandoorUser}" = {
      after = [
        "user@${toString tandoorUid}.service"
        "opnix-secrets.service"
      ];
      wants = [
        "user@${toString tandoorUid}.service"
        "opnix-secrets.service"
      ];
    };

    boot.initrd.impermanence.persist.directories = [
      {
        directory = tandoorAppDir;
        user = tandoorUser;
        group = tandoorGroup;
        mode = "0750";
      }
    ];

    home-manager.users.${tandoorUser} = {
      services.rclone.remotes = [ "koofr" ];
      home.username = tandoorUser;
      home.stateVersion = "26.05";
      imports = with config.flake.modules.homeManager; [
        base
        backup
        podman-secrets
        homelab-tandoor
      ];
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
        ALLOWED_HOSTS = "*";
        DB_ENGINE = "django.db.backends.postgresql";
        POSTGRES_HOST = "db";
        POSTGRES_DB = tandoorDbName;
        POSTGRES_USER = tandoorDbUser;
        TZ = osConfig.time.timeZone;
      };

      oidcEnv = lib.optionalAttrs (tandoorOidcSecretFile != null) {
        OIDC_ENDPOINT = "https://${hosts.auth}";
        OIDC_CLIENT_ID = tandoorOidcClientId;
        OIDC_SCOPES = "openid,profile,email";
      };

      oidcSecrets = lib.optionalAttrs (tandoorOidcSecretFile != null) {
        OIDC_CLIENT_SECRET = tandoorOidcSecretFile;
      };
    in
    {
      config = {
        xdg.configFile."containers/storage.conf".text = ''
          [storage]
          graphroot = "${tandoorAppDir}/containers"
        '';

        services.backup.jobs.tandoor = {
          paths = [
            "${tandoorDataDir}/postgres"
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
          volumes = [ "${tandoorDataDir}/postgres:/var/lib/postgresql/data" ];

          environment = {
            TZ = osConfig.time.timeZone;
            POSTGRES_USER = tandoorDbUser;
            POSTGRES_DB = tandoorDbName;
          };

          secrets = {
            POSTGRES_PASSWORD = tandoorDbPasswordFile;
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
            SECRET_KEY = tandoorSecretKeyFile;
            POSTGRES_PASSWORD = tandoorDbPasswordFile;
          }
          // oidcSecrets;

          extraConfig = {
            Unit = {
              After = [ "podman-tandoor-db.service" ];
              Requires = [ "podman-tandoor-db.service" ];
            };
            Container.NoNewPrivileges = true;
          };
        };
      };
    };
}
