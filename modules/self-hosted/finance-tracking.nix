{ config, ... }:
let
  domain = config.flake.meta.reverse-proxy.domain;
  port = config.flake.meta.reverse-proxy.ports.sure-finance;
in
{
  flake.modules.nixos.homelab = {
    services.caddy.virtualHosts."finance.${domain}" = {
      useACMEHost = domain;
      extraConfig = ''
        import reverse_proxy_common
        reverse_proxy localhost:${toString port}
      '';
    };
  };

  flake.modules.homeManager.homelab = hmArgs: {
    services.backup.jobs.sure-finance = {
      paths = [
        "/var/lib/containers/sure-finance/postgres"
        "/var/lib/containers/sure-finance/storage"
      ];
      schedule = "daily";
      retention = "weekly";
      providers = [ "koofr" ];
      encryptionKey =
        hmArgs.config.services.onepassword-secrets.secretPaths.backupSureFinanceEncryptionKey;
    };

    programs.onepassword-secrets.secrets.backupSureFinanceEncryptionKey = {
      path = ".secrets/backup/sure-finance/encryption_key";
      reference = "op://Homelab/Backup/sure-finance/password";
    };
  };

  flake.homelab.services.sure-finance.module = hmArgs: {
    config = {
      inherit port;
      enable = true;
      database.passwordFile =
        hmArgs.config.services.onepassword-secrets.secretPaths.sureFinancePostgresPasswordPath;
      secretKeyBaseFile =
        hmArgs.config.services.onepassword-secrets.secretPaths.sureFinanceSecretKeyBasePath;
      openaiTokenFile = hmArgs.config.services.onepassword-secrets.secretPaths.sureFinanceOpenAiTokenPath;
    };

    programs.onepassword-secrets.secrets = {
      sureFinanceSecretKeyBasePath = {
        path = "/run/secrets/sure-finance/secret_key";
        reference = "op://HomeLab/Sure Finance/Authentication/secret key";
        owner = config.flake.meta.sure-finance.user;
        group = config.flake.meta.sure-finance.group;
      };
      sureFinancePostgresPasswordPath = {
        path = "/run/secrets/sure-finance/postgres_password";
        reference = "op://HomeLab/Sure Finance/Database/password";
        owner = config.flake.meta.sure-finance.user;
        group = config.flake.meta.sure-finance.group;
      };
      sureFinanceOpenAiTokenPath = {
        path = "/run/secrets/sure-finance/openai_token";
        reference = "op://HomeLab/Sure Finance/AI/api key";
        owner = config.flake.meta.sure-finance.user;
        group = config.flake.meta.sure-finance.group;
      };
    };
  };
}
