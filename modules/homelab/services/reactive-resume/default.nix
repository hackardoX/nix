{
  config,
  lib,
  ...
}:
let
  reactiveResumeUid = 907;
  reactiveResumeGid = 907;
  reactiveResumeUser = "reactive-resume";
  reactiveResumeGroup = "reactive-resume";
  reactiveResumeAppDir = "/var/lib/containers/reactive-resume";
  reactiveResumeDataDir = "/var/lib/data/reactive-resume";

  hosts = config.flake.meta.reverse-proxy.hosts;
  reverseProxyPort = config.flake.meta.reverse-proxy.ports.reactive-resume;

  reactiveResumeImage = "amruthpillai/reactive-resume:v5.2.4";
  reactiveResumePort = 3000;
  reactiveResumeDbName = "rxresume";
  reactiveResumeDbUser = "rxresume";
  reactiveResumeDbPasswordFile = "/run/secrets/reactive-resume/db_password";
  reactiveResumeAuthSecretFile = "/run/secrets/reactive-resume/auth_secret";

  reactiveResumeAppUrl = "https://${hosts.rxresume}";
  reactiveResumeOidcClientId = config.flake.meta.oidc-clients.reactive-resume.clientId;
  reactiveResumeOidcSecretFile = "/run/secrets/reactive-resume/oidc_client_secret";
in
{
  flake.homepage.services.reactive-resume = {
    category = "Productivity";
    name = "Reactive Resume";
    description = "Resume Builder";
    icon = "sh-reactive-resume-light.webp";
    href = "https://${hosts.rxresume}";
    siteMonitor = "http://localhost:${toString reverseProxyPort}/api/health";
    container = "reactive-resume";
    dockerServer = "reactive-resume";
    dockerSocketProxyPort = config.flake.meta.reverse-proxy.ports.reactive-resume-docker-socket-proxy;
    pingPort = reverseProxyPort;
  };

  flake.modules.nixos.homelab-reactive-resume = {
    users.users.${reactiveResumeUser} = {
      uid = reactiveResumeUid;
      isSystemUser = true;
      group = reactiveResumeGroup;
      extraGroups = [
        "homelab-users"
        "rclone"
      ];
      createHome = true;
      home = "/var/lib/${reactiveResumeUser}";
      autoSubUidGidRange = true;
      linger = true;
    };

    users.groups.${reactiveResumeGroup} = {
      gid = reactiveResumeGid;
    };

    home-manager.users.${reactiveResumeUser} = {
      imports = with config.flake.modules.homeManager; [
        base
        backup
        podman-secrets
        homelab-beszel-agent
        homelab-docker-socket-proxy
        homelab-reactive-resume
      ];
      home.username = reactiveResumeUser;
      home.stateVersion = "26.05";
      services.rclone.remotes = [ "koofr" ];
      services.homelab-docker-socket-proxy = {
        enable = true;
        port = config.flake.meta.reverse-proxy.ports.reactive-resume-docker-socket-proxy;
      };
      services.homelab-beszel-agent = {
        enable = true;
        port = config.flake.meta.reverse-proxy.ports.beszel-agent-reactive-resume;
      };
    };

    services.onepassword-secrets.secrets = {
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
        reference = "op://Homelab/Backup/Reactive Resume/password";
        owner = reactiveResumeUser;
        group = reactiveResumeGroup;
      };
    };

    systemd.tmpfiles.rules = [
      "d ${reactiveResumeAppDir} 0750 ${reactiveResumeUser} ${reactiveResumeGroup} -"
      "d ${reactiveResumeAppDir}/data 0750 ${reactiveResumeUser} ${reactiveResumeGroup} -"
      "d ${reactiveResumeDataDir}/postgres 0750 ${reactiveResumeUser} ${reactiveResumeGroup} -"
      "d ${reactiveResumeAppDir}/storage 0750 ${reactiveResumeUser} ${reactiveResumeGroup} -"
    ];

    boot.initrd.impermanence.persist.directories = [
      {
        directory = reactiveResumeAppDir;
        user = reactiveResumeUser;
        group = reactiveResumeGroup;
        mode = "0750";
      }
    ];

    services.caddy.virtualHosts."${hosts.rxresume}" = {
      extraConfig = ''
        import reverse_proxy_common
        reverse_proxy localhost:${toString reverseProxyPort}
      '';
    };
  };

  flake.modules.homeManager.homelab-reactive-resume =
    { osConfig, pkgs, ... }:
    let
      entrypointScript = pkgs.writeTextFile {
        name = "reactive-resume-entrypoint";
        executable = true;
        text = ''
          #!/bin/sh
          export DATABASE_URL="postgresql://${reactiveResumeDbUser}:''${DATABASE_PASSWORD}@db:5432/${reactiveResumeDbName}"
          exec "$@"
        '';
      };
      oidcEnv = lib.optionalAttrs (reactiveResumeOidcSecretFile != null) {
        OAUTH_CLIENT_ID = reactiveResumeOidcClientId;
        OAUTH_PROVIDER_NAME = "Authelia";
        OAUTH_DISCOVERY_URL = "https://${hosts.auth}/.well-known/openid-configuration";
        OAUTH_SCOPES = "openid profile email";
      };

      oidcSecrets = lib.optionalAttrs (reactiveResumeOidcSecretFile != null) {
        OAUTH_CLIENT_SECRET = reactiveResumeOidcSecretFile;
      };
    in
    {
      config = {
        xdg.configFile."containers/storage.conf".text = ''
          [storage]
          graphroot = "${reactiveResumeAppDir}/containers"
        '';

        services.backup.jobs.reactive-resume = {
          paths = [
            "${reactiveResumeAppDir}/data"
          ];
          schedule = "daily";
          retention = "standard";
          providers = [ "koofr" ];
          encryptionKey = osConfig.services.onepassword-secrets.secretPaths.backupReactiveResumeEncryptionKey;
          db = {
            type = "postgres";
            user = "rxresume";
            passwordFile = osConfig.services.onepassword-secrets.secretPaths.reactiveResumeDbPassword;
            container = {
              type = "podman";
              name = "reactive-resume-db";
            };
          };
        };

        services.podman.enable = true;
        services.podman.networks.reactive-resume.driver = "bridge";

        services.podman.containers.reactive-resume-db = {
          image = "docker.io/library/postgres:16.14";
          autoStart = true;
          userNS = "keep-id:uid=999,gid=999";
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

          extraConfig = {
            Container = {
              LogDriver = "journald";
              HealthCmd = "pg_isready -U ${reactiveResumeDbUser} -d ${reactiveResumeDbName}";
              HealthInterval = "5s";
              HealthTimeout = "5s";
              HealthRetries = 5;
              NoNewPrivileges = true;
            };
          };
        };

        services.podman.containers.reactive-resume = {
          image = reactiveResumeImage;
          autoStart = true;
          userNS = "keep-id:uid=1000,gid=1000";
          network = [ "reactive-resume.network" ];
          networkAlias = [ "app" ];
          ports = [ "${toString reverseProxyPort}:${toString reactiveResumePort}" ];

          volumes = [
            "${entrypointScript}:/entrypoint.sh:ro"
            "${reactiveResumeAppDir}/data:/app/data"
          ];

          environment = {
            TZ = osConfig.time.timeZone;
            APP_URL = reactiveResumeAppUrl;
            AUTH_TRUST_HOST = "true";
            BETTER_AUTH_URL = reactiveResumeAppUrl;
            FLAG_DISABLE_EMAIL_AUTH = "true";
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
              After = [ "podman-reactive-resume-db.service" ];
              Requires = [ "podman-reactive-resume-db.service" ];
            };
            Container = {
              LogDriver = "journald";
              Entrypoint = [ "/entrypoint.sh" ];
              Exec = "node apps/server/dist/index.mjs";
              HealthCmd = "node -e \"fetch('http://127.0.0.1:3000/api/health').then((r) => { if (!r.ok) process.exit(1); }).catch(() => process.exit(1));\"";
              HealthInterval = "30s";
              HealthTimeout = "10s";
              HealthRetries = 3;
              HealthStartPeriod = "30s";
              NoNewPrivileges = true;
            };
          };
        };
      };
    };
}
