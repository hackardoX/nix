{
  flake.modules.nixos.homelab = nixosArgs: {
    imports = [ ./_services/sure-finance/sure-finance.nix ];
    services = {
      sure-finance = {
        enable = true;
        domain = "finance.aegisinbox.com";
        secrets = {
          secretKeyBasePath =
            nixosArgs.config.services.onepassword-secrets.secretPaths.sureFinanceSecretKeyBasePath;
          postgresPasswordPath =
            nixosArgs.config.services.onepassword-secrets.secretPaths.sureFinancePostgresPasswordPath;
          redisPasswordPath =
            nixosArgs.config.services.onepassword-secrets.secretPaths.sureFinanceRedisPasswordPath;
          openAiTokenPath =
            nixosArgs.config.services.onepassword-secrets.secretPaths.sureFinanceOpenAiTokenPath;
        };
        openai = {
          model = "mistral-large-latest";
          baseUrl = "https://api.mistral.ai/v1";
        };

        database.enable = true;
        redis.enable = true;

        nginx = {
          enable = true;
          enableACME = true;
        };
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
          mode = "0640";
        };
        sureFinanceRedisPasswordPath = {
          path = "/run/secrets/sure-finance/redis_password";
          reference = "op://Development/Sure Finance Secrets/redis password";
          owner = "sure-finance";
          group = "sure-finance";
          mode = "0640";
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
