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

  flake.modules.homeManager."${config.flake.meta.sure-finance.user}@homelab" = hmArgs: {
    services.sure-finance = {
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
        reference = "op://Development/Sure Finance Secrets/secret key";
        owner = config.flake.meta.sure-finance.user;
        group = config.flake.meta.sure-finance.group;
      };
      sureFinancePostgresPasswordPath = {
        path = "/run/secrets/sure-finance/postgres_password";
        reference = "op://Development/Sure Finance Secrets/postgres password";
        owner = config.flake.meta.sure-finance.user;
        group = config.flake.meta.sure-finance.group;
      };
      sureFinanceOpenAiTokenPath = {
        path = "/run/secrets/sure-finance/openai_token";
        reference = "op://Development/Mistral API Key - Sure Finance/credential";
        owner = config.flake.meta.sure-finance.user;
        group = config.flake.meta.sure-finance.group;
      };
    };
  };
}
