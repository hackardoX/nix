{
  config,
  lib,
  ...
}:
let
  reactiveResumeUser = "reactive-resume";
  reactiveResumeGroup = "reactive-resume";
  reactiveResumeAppDir = "/var/lib/containers/reactive-resume";
  reactiveResumeDataDir = "/var/lib/data/reactive-resume";

  domain = config.flake.meta.reverse-proxy.domain;
  reverseProxyPort = config.flake.meta.reverse-proxy.ports.reactive-resume;
  mkHomepageLabels = config.flake.lib.mkHomepageLabels;

  reactiveResumeImage = "amruthpillai/reactive-resume:latest";
  reactiveResumePort = 3000;
  reactiveResumeDbName = "rxresume";
  reactiveResumeDbUser = "rxresume";
  reactiveResumeDbPasswordFile = "/run/secrets/reactive-resume/db_password";
  reactiveResumeAuthSecretFile = "/run/secrets/reactive-resume/auth_secret";

  reactiveResumeAppUrl = "https://rxresume.${domain}";
  reactiveResumeOidcClientId = config.flake.meta.oidc-clients.reactive-resume.clientId or "";
  reactiveResumeOidcSecretFile = "/run/secrets/reactive-resume/oidc_client_secret";
in
{
  flake.modules.nixos.reactive-resume = {
    users.users.${reactiveResumeUser} = {
      isSystemUser = true;
      group = reactiveResumeGroup;
      extraGroups = [ "podman" ];
      createHome = true;
      home = "/var/lib/${reactiveResumeUser}";
      autoSubUidGidRange = true;
      linger = true;
    };

    users.groups.${reactiveResumeGroup} = { };

    home-manager.users.${reactiveResumeUser} = {
      home.username = reactiveResumeUser;
      home.stateVersion = "24.11";
      imports = with config.flake.modules.homeManager; [
        base
        backup
        podman-secrets
        reactive-resume
      ];
    };

    services.caddy.virtualHosts."rxresume.${domain}" = {
      extraConfig = ''
        import reverse_proxy_common
        reverse_proxy localhost:${toString reverseProxyPort}
      '';
    };
  };

  flake.modules.homeManager.reactive-resume =
    hmArgs@{ osConfig, pkgs, ... }:
    let
      entrypointScript = pkgs.writeShellScript "reactive-resume-entrypoint" ''
        DB_PASSWORD=$(cat /run/secrets/DATABASE_PASSWORD)
        export DATABASE_URL="postgresql://${reactiveResumeDbUser}:''${DB_PASSWORD}@db:5432/${reactiveResumeDbName}"
        exec "$@"
      '';

      oidcEnv = lib.optionalAttrs (reactiveResumeOidcSecretFile != null) {
        OIDC_ENABLED = "true";
        OIDC_PROVIDER = "authelia";
        OIDC_CLIENT_ID = reactiveResumeOidcClientId;
        OIDC_ISSUER = "https://auth.${domain}";
        OIDC_SCOPES = "openid profile email";
      };

      oidcSecrets = lib.optionalAttrs (reactiveResumeOidcSecretFile != null) {
        OIDC_CLIENT_SECRET = reactiveResumeOidcSecretFile;
      };
    in
    {
      config = {
        programs.onepassword-secrets.secrets = {
          reactiveResumeAuthSecret = {
            path = "/run/secrets/reactive-resume/auth_secret";
            reference = "op://Homelab/Reactive Resume/Authentication/secret";
            owner = reactiveResumeUser;
            group = reactiveResumeGroup;
          };
          reactiveResumeDbPassword = {
            path = "/run/secrets/reactive-resume/db_password";
            reference = "op://Homelab/Reactive Resume/Database/password";
            owner = reactiveResumeUser;
            group = reactiveResumeGroup;
          };
          reactiveResumeOidcClientSecret = {
            path = "/run/secrets/reactive-resume/oidc_client_secret";
            reference = "op://Homelab/Reactive Resume/Authentication/OIDC Client Secret";
            owner = reactiveResumeUser;
            group = reactiveResumeGroup;
          };
          backupReactiveResumeEncryptionKey = {
            path = "/run/secrets/reactive-resume/backup_encryption_key";
            reference = "op://Homelab/Backup/reactive-resume/password";
            owner = reactiveResumeUser;
            group = reactiveResumeGroup;
          };
        };

        services.backup.jobs.reactive-resume = {
          paths = [
            "${reactiveResumeDataDir}/postgres"
            "${reactiveResumeAppDir}/data"
          ];
          schedule = "daily";
          retention = "standard";
          providers = [ "koofr" ];
          encryptionKey =
            hmArgs.config.services.onepassword-secrets.secretPaths.backupReactiveResumeEncryptionKey;
        };

        services.podman.enable = true;
        services.podman.networks.reactive-resume.driver = "bridge";

        services.podman.containers.reactive-resume-db = {
          image = "docker.io/library/postgres:16";
          autoStart = true;
          userNS = "keep-id";
          network = [ "reactive-resume.network" ];
          networkAlias = [ "db" ];
          volumes = [ "${reactiveResumeDataDir}/postgres:/var/lib/postgresql/data" ];

          environment = {
            TZ = osConfig.time.timeZone;
            POSTGRES_USER = reactiveResumeDbUser;
            POSTGRES_DB = reactiveResumeDbName;
          };

          secrets = {
            POSTGRES_PASSWORD = reactiveResumeDbPasswordFile;
          };

          extraConfig.Container = {
            HealthCmd = "pg_isready -U ${reactiveResumeDbUser} -d ${reactiveResumeDbName}";
            HealthInterval = "5s";
            HealthTimeout = "5s";
            HealthRetries = 5;
            NoNewPrivileges = true;
          };
        };

        services.podman.containers.reactive-resume = {
          image = reactiveResumeImage;
          autoStart = true;
          userNS = "keep-id";
          network = [ "reactive-resume.network" ];
          networkAlias = [ "app" ];
          ports = [ "${toString reverseProxyPort}:${toString reactiveResumePort}" ];

          labels = mkHomepageLabels {
            category = "Productivity";
            name = "Reactive Resume";
            description = "Resume Builder";
            icon = "mdi-file-document-outline";
            href = "http://localhost:${toString reverseProxyPort}";
          };

          volumes = [
            "${entrypointScript}:/entrypoint.sh:ro"
            "${reactiveResumeAppDir}/data:/app/data"
          ];

          environment = {
            TZ = osConfig.time.timeZone;
            APP_URL = reactiveResumeAppUrl;
            FLAG_DISABLE_SIGNUPS = "true";
            FLAG_DISABLE_EMAIL_AUTH = "false";
            FLAG_DISABLE_IMAGE_PROCESSING = "false";
          }
          // oidcEnv;

          secrets = {
            AUTH_SECRET = reactiveResumeAuthSecretFile;
            DATABASE_PASSWORD = reactiveResumeDbPasswordFile;
          }
          // oidcSecrets;

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
}
