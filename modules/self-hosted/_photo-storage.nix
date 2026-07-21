{ config, ... }:
let
  domain = config.flake.meta.reverse-proxy.domain;
  port = config.flake.meta.reverse-proxy.ports.immich;
in
{
  flake.modules.nixos.homelab = {
    services.caddy.virtualHosts."immich.${domain}" = {
      extraConfig = ''
        import reverse_proxy_common

        request_body {
          max_size 50GB
        }

        reverse_proxy localhost:${toString port} {
          transport http {
            read_timeout 600s
            write_timeout 600s
          }
        }
      '';
    };
  };

  flake.modules.homeManager.homelab = hmArgs: {
    services.backup.jobs.immich = {
      paths = [
        "/var/lib/containers/immich/photos/library"
        "/var/lib/containers/immich/photos/upload"
        "/var/lib/containers/immich/photos/profile"
        "/var/lib/containers/immich/photos/backups"
      ];
      schedule = "daily";
      retention = "standard";
      providers = [ "koofr" ];
      encryptionKey = hmArgs.config.services.onepassword-secrets.secretPaths.backupImmichEncryptionKey;
    };

    programs.onepassword-secrets.secrets.backupImmichEncryptionKey = {
      path = ".secrets/backup/immich/encryption_key";
      reference = "op://Homelab/Backup/immich/password";
      owner = config.flake.meta.immich.user;
      group = config.flake.meta.immich.group;
    };
  };

  flake.homelab.services.immich.module = hmArgs: {
    config = {
      enable = true;
      port = port;
      dbPasswordFile = hmArgs.config.services.onepassword-secrets.secretPaths.immichDbPassword;
      oauthClientSecretFile =
        hmArgs.config.services.onepassword-secrets.secretPaths.immichOidcClientSecret;

      programs.onepassword-secrets.secrets = {
        immichDbPassword = {
          path = ".secrets/immich/db_password";
          reference = "op://Homelab/Immich/Database/password";
          owner = config.flake.meta.immich.user;
          group = config.flake.meta.immich.group;
        };

        immichOidcClientSecret = {
          path = "/run/secrets/immich/oidc_client_secret";
          reference = "op://Homelab/Immich/Authentication/OIDC client secret";
          owner = config.flake.meta.immich.user;
          group = config.flake.meta.immich.group;
        };
      };
    };
  };
}
