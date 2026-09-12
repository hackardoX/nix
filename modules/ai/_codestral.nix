{
  config = {
    flake.meta.aiProviders.codestral = {
      endpoint = "https://codestral.mistral.ai/v1";
      apiKeyEnv = "MISTRAL_CODESTRAL_API_KEY";
      models = { };
    };

    flake.modules.homeManager.ai-codestral = hmArgs: {
      home.sessionVariables.MISTRAL_CODESTRAL_API_KEY = "$(cat ${
        hmArgs.config.sops.secrets."ai/mistral_codestral_api_key".path
      })";
      sops.secrets."ai/mistral_codestral_api_key" = {
        path = "${hmArgs.config.home.homeDirectory}/.secrets/.mistral_codestral_key";
      };
    };
  };
}
