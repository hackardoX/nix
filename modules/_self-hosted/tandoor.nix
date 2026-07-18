{ config, ... }:
let
  domain = config.flake.meta.reverse-proxy.domain;
  port = config.flake.meta.reverse-proxy.ports.tandoor;
  appSubDomain = "recipes";
in
{
  flake.modules.nixos.homelab = {
    services.caddy.virtualHosts."${appSubDomain}.${domain}" = {
      useACMEHost = domain;
      extraConfig = ''
        import reverse_proxy_common
        reverse_proxy localhost:${toString port}
      '';
    };
  };

  flake.modules.homeManager.homelab = hmArgs: {
    services.backup.jobs.tandoor = {
      paths = [
        "/var/lib/containers/tandoor/postgres"
        "/var/lib/containers/tandoor/mediafiles"
      ];
      schedule = "daily";
      retention = "standard";
      providers = [ "koofr" ];
      encryptionKey = hmArgs.config.services.onepassword-secrets.secretPaths.backupTandoorEncryptionKey;
    };

    programs.onepassword-secrets.secrets.backupTandoorEncryptionKey = {
      path = ".secrets/backup/tandoor/encryption_key";
      reference = "op://Homelab/Backup/tandoor/password";
      owner = config.flake.meta.tandoor.user;
      group = config.flake.meta.tandoor.group;
    };
  };

  flake.homelab.services.tandoor.module = hmArgs: {
    config = {
      enable = true;
      port = port;
      secretKeyFile = hmArgs.config.services.onepassword-secrets.secretPaths.tandoorSecretKeyPath;
      database.passwordFile =
        hmArgs.config.services.onepassword-secrets.secretPaths.tandoorDbPasswordPath;
      oidcClientSecretFile =
        hmArgs.config.services.onepassword-secrets.secretPaths.tandoorOidcClientSecret;
    };

    programs.onepassword-secrets.secrets = {
      tandoorSecretKeyPath = {
        path = "/run/secrets/tandoor/secret_key";
        reference = "op://Homelab/Tandoor/Authentication/secret key";
        owner = config.flake.meta.tandoor.user;
        group = config.flake.meta.tandoor.group;
      };

      tandoorDbPasswordPath = {
        path = "/run/secrets/tandoor/db_password";
        reference = "op://Homelab/Tandoor/Database/password";
        owner = config.flake.meta.tandoor.user;
        group = config.flake.meta.tandoor.group;
      };

      tandoorOidcClientSecret = {
        path = "/run/secrets/tandoor/oidc_client_secret";
        reference = "op://Homelab/Tandoor/Authentication/OIDC client secret";
        owner = config.flake.meta.tandoor.user;
        group = config.flake.meta.tandoor.group;
      };
    };
  };
}
