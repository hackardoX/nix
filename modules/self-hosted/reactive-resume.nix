{ config, ... }:
let
  domain = config.flake.meta.reverse-proxy.domain;
  port = config.flake.meta.reverse-proxy.ports.reactive-resume;
  appSubDomain = "rxresume";
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
    services.backup.jobs.reactive-resume = {
      paths = [
        "/var/lib/containers/reactive-resume/postgres"
        "/var/lib/containers/reactive-resume/data"
      ];
      schedule = "daily";
      retention = "weekly";
      providers = [ "koofr" ];
      encryptionKey =
        hmArgs.config.services.onepassword-secrets.secretPaths.backupReactiveResumeEncryptionKey;
    };

    programs.onepassword-secrets.secrets.backupReactiveResumeEncryptionKey = {
      path = ".secrets/backup/reactive-resume/encryption_key";
      reference = "op://Homelab/Backup/reactive-resume/password";
    };
  };

  flake.homelab.services.reactive-resume.module = hmArgs: {
    config = {
      enable = true;
      port = port;
      appUrl = "https://${appSubDomain}.${domain}";
      authSecretFile =
        hmArgs.config.services.onepassword-secrets.secretPaths.reactiveResumeAuthSecretPath;
      database.passwordFile =
        hmArgs.config.services.onepassword-secrets.secretPaths.reactiveResumeDbPasswordPath;
      oidcClientSecretFile =
        hmArgs.config.services.onepassword-secrets.secretPaths.reactiveResumeOidcClientSecret;
    };

    programs.onepassword-secrets.secrets = {
      reactiveResumeAuthSecretPath = {
        path = "/run/secrets/reactive-resume/auth_secret";
        reference = "op://Homelab/Reactive Resume/Authentication/secret";
        owner = config.flake.meta.reactive-resume.user;
        group = config.flake.meta.reactive-resume.group;
      };

      reactiveResumeDbPasswordPath = {
        path = "/run/secrets/reactive-resume/db_password";
        reference = "op://Homelab/Reactive Resume/Database/password";
        owner = config.flake.meta.reactive-resume.user;
        group = config.flake.meta.reactive-resume.group;
      };

      reactiveResumeOidcClientSecret = {
        path = "/run/secrets/reactive-resume/oidc_client_secret";
        reference = "op://Homelab/Reactive Resume/Authentication/OIDC Client Secret";
        owner = config.flake.meta.reactive-resume.user;
        group = config.flake.meta.reactive-resume.group;
      };
    };
  };
}
