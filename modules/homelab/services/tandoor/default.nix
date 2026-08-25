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
  domain = config.flake.meta.reverse-proxy.domain;
  reverseProxyPort = config.flake.meta.reverse-proxy.ports.tandoor;
  tandoorImage = "ghcr.io/tandoorrecipes/recipes:2.6.13";
  tandoorPort = 8080;
  tandoorDbName = "tandoor";
  tandoorDbUser = "tandoor";
in
{
  flake.meta.homepage.services.tandoor = {
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
    dockerSocketProxyPort = config.flake.meta.reverse-proxy.ports.tandoor-docker-socket-proxy;
    pingPort = reverseProxyPort;
  };

  flake.meta.oidc-clients.tandoor = {
    clientId = "tandoor";
    clientName = "Tandoor Recipes";
    policy = "two_factor";
    redirectUris = [ "https://${hosts.recipes}/accounts/oidc/authelia/login/callback/" ];
    secretName = "autheliaTandoorOidcSecret";
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
        port = config.flake.meta.reverse-proxy.ports.tandoor-docker-socket-proxy;
      };
      services.rclone.remotes = [ "koofr" ];
    };

    services.onepassword-secrets.secrets = {
      tandoorFDCApiKey = {
        path = "/run/secrets/tandoor/fdc_api_key";
        reference = "op://HomeLab/Tandoor/External API Keys/FDC";
        owner = tandoorUser;
        group = tandoorGroup;
      };
      tandoorSecretKey = {
        path = "/run/secrets/tandoor/secret_key";
        reference = "op://HomeLab/Tandoor/Authentication/secret key";
        owner = tandoorUser;
        group = tandoorGroup;
      };
      tandoorDbPassword = {
        path = "/run/secrets/tandoor/db_password";
        reference = "op://HomeLab/Tandoor/Database/password";
        owner = tandoorUser;
        group = tandoorGroup;
      };
      tandoorOidcClientSecret = {
        path = "/run/secrets/tandoor/oidc_client_secret";
        reference = "op://HomeLab/Tandoor/Authentication/OIDC client secret";
        owner = tandoorUser;
        group = tandoorGroup;
      };
      tandoorResendApiKey = {
        path = "/run/secrets/tandoor/resend_api_key";
        reference = "op://HomeLab/Tandoor/Resend/api key";
        owner = tandoorUser;
        group = tandoorGroup;
      };
      backupTandoorEncryptionKey = {
        path = "/run/secrets/tandoor/backup_encryption_key";
        reference = "op://HomeLab/Backup/Tandoor/password";
        owner = tandoorUser;
        group = tandoorGroup;
      };
      autheliaTandoorOidcSecret = {
        path = "/run/secrets/authelia/tandoor_oidc_secret";
        reference = "op://HomeLab/Tandoor/Authentication/OIDC client secret";
        owner = config.flake.meta.users.authelia.name;
        group = config.flake.meta.users.authelia.primaryGroup;
        services = [ "authelia-default.service" ];
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
    { osConfig, pkgs, ... }:
    let
      oidcClientId = config.flake.meta.oidc-clients.tandoor.clientId;
      oidcProvidersFile = "/run/user/${toString tandoorUid}/tandoor-socialaccount-providers.json";

      tandoorSocialaccountProviders = pkgs.writeShellApplication {
        name = "tandoor-socialaccount-providers";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.jq
        ];
        text = ''
          set -euo pipefail
          install -D -m 600 /dev/null ${oidcProvidersFile}
          jq -n --arg secret "$(cat ${osConfig.services.onepassword-secrets.secretPaths.tandoorOidcClientSecret})" \
            '{openid_connect: {SCOPE: ["openid", "profile", "email"], OAUTH_PKCE_ENABLED: true, APPS: [{provider_id: "authelia", name: "Authelia", client_id: "${oidcClientId}", secret: $secret, settings: {server_url: "https://${hosts.auth}/.well-known/openid-configuration", token_auth_method: "client_secret_post"}}]}}' \
            > ${oidcProvidersFile}
        '';
      };
    in
    {
      config = {
        services.backup.jobs.tandoor = {
          paths = [
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
          userNS = "keep-id";
          network = [ "tandoor.network" ];
          networkAlias = [ "app" ];
          ports = [ "${toString reverseProxyPort}:${toString tandoorPort}" ];

          volumes = [
            "${tandoorAppDir}/staticfiles:/opt/recipes/staticfiles"
            "${tandoorAppDir}/mediafiles:/opt/recipes/mediafiles"
            "${oidcProvidersFile}:/run/socialaccount_providers.json:ro"
          ];

          environment = {
            ALLOWED_HOSTS = ".localhost,127.0.0.1,[::1],${hosts.recipes}";
            DB_ENGINE = "django.db.backends.postgresql";
            DEFAULT_FROM_EMAIL = "tandoor@${domain}";
            EMAIL_HOST = "smtp.resend.com";
            EMAIL_HOST_USER = "resend";
            EMAIL_PORT = 587;
            EMAIL_USE_TLS = 1;
            HIDE_LOGIN_FORM = 1;
            POSTGRES_HOST = "db";
            POSTGRES_DB = tandoorDbName;
            POSTGRES_USER = tandoorDbUser;
            SOCIAL_PROVIDERS = "allauth.socialaccount.providers.openid_connect";
            SOCIALACCOUNT_PROVIDERS_FILE = "/run/socialaccount_providers.json";
            TANDOOR_PORT = tandoorPort;
            TZ = osConfig.time.timeZone;
          };

          secrets = {
            EMAIL_HOST_PASSWORD = osConfig.services.onepassword-secrets.secretPaths.tandoorResendApiKey;
            FDC_API_KEY = osConfig.services.onepassword-secrets.secretPaths.tandoorFDCApiKey;
            SECRET_KEY = osConfig.services.onepassword-secrets.secretPaths.tandoorSecretKey;
            POSTGRES_PASSWORD = osConfig.services.onepassword-secrets.secretPaths.tandoorDbPassword;
          };

          extraConfig = {
            Unit = {
              After = [ "podman-tandoor-db.service" ];
              Requires = [ "podman-tandoor-db.service" ];
            };
            Container = {
              AddCapability = [
                "CAP_CHOWN"
                "CAP_SETUID"
                "CAP_SETGID"
                "CAP_DAC_OVERRIDE"
                "CAP_FOWNER"
              ];
              HealthCmd = "wget -qO- http://localhost:${toString tandoorPort} || exit 1";
              HealthInterval = "30s";
              HealthTimeout = "10s";
              HealthRetries = 3;
              HealthStartPeriod = "30s";
              NoNewPrivileges = true;
            };
            Service = {
              ExecStartPre = [ (lib.getExe tandoorSocialaccountProviders) ];
            };
          };
        };
      };
    };
}
