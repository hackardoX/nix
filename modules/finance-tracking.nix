{
  flake.modules.homeManager.homelab = hmArgs: {
    services = {
      sure-finance = {
        enable = true;
        domain = "finance.aegisinbox.com";
        port = "";
        database.passwordFile =
          hmArgs.config.services.onepassword-secrets.secretPaths.sureFinancePostgresPasswordPath;
        secretKeyBaseFile =
          hmArgs.config.services.onepassword-secrets.secretPaths.sureFinanceSecretKeyBasePath;
        openaiTokenFile = hmArgs.config.services.onepassword-secrets.secretPaths.sureFinanceOpenAiTokenPath;
      };

      onepassword-secrets.secrets = {
        sureFinanceSecretKeyBasePath = {
          path = "/run/secrets/sure-finance/secret_key";
          reference = "op://Development/Sure Finance Secrets/secret key";
          owner = "sure-finance";
          group = "sure-finance";
        };
        sureFinancePostgresPasswordPath = {
          path = "/run/secrets/sure-finance/postgres_password";
          reference = "op://Development/Sure Finance Secrets/postgres password";
          owner = "sure-finance";
          group = "sure-finance";
        };
        sureFinanceOpenAiTokenPath = {
          path = "/run/secrets/sure-finance/openai_token";
          reference = "op://Development/Mistral API Key - Sure Finance/credential";
          owner = "sure-finance";
          group = "sure-finance";
        };
      };
    };
  };
}
