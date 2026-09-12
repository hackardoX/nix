{
  config = {
    flake.meta.aiProviders.lumo = {
      endpoint = "https://lumo.proton.me/api/ai/v1";
      apiKeyEnv = "LUMO_API_KEY";
      models = {
        lumo-max = {
          name = "Lumo Max";
          options = {
            reasoningEffort = "high";
          };
          variants = {
            fast = {
              reasoningEffort = "none";
            };
            "thinking (default)" = {
              reasoningEffort = "high";
            };
            "max thinking" = {
              reasoningEffort = "max";
            };
          };
        };
        lumo-lite = {
          name = "Lumo Lite";
          modalities = {
            input = [
              "text"
              "image"
            ];
            output = [ "text" ];
          };
          options = {
            reasoningEffort = "high";
          };
          variants = {
            fast = {
              reasoningEffort = "none";
            };
            "thinking (default)" = {
              reasoningEffort = "high";
            };
          };
        };
      };
    };

    flake.modules.homeManager.dev = hmArgs: {
      home.sessionVariables.LUMO_API_KEY = "$(cat ${hmArgs.config.sops.secrets."ai/lumo_api_key".path})";
      sops.secrets."ai/lumo_api_key" = {
        path = "${hmArgs.config.home.homeDirectory}/.secrets/.lumo_key";
      };
    };
  };
}
