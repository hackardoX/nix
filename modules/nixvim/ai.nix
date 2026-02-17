{
  flake.modules.nixvim.dev = {
    plugins.avante = {
      enable = true;
      settings = {

        auto_suggestions_provider = "mistral_codestral";
        provider = "mistral_devstral";
        providers = {
          claude = {
            endpoint = "https://api.anthropic.com";
            model = "claude-4-6-opus-20260205";
            extra_request_body = {
              temperature = 0;
              max_tokens = 8192;
            };
          };
          mistral_codestral = {
            __inherited_from = "openai";
            api_key_name = "MISTRAL_CODESTRAL_API_KEY";
            endpoint = "https://codestral.mistral.ai/v1";
            model = "codestral-latest";
            extra_request_body = {
              max_tokens = 4096;
            };
          };
          mistral_devstral = {
            __inherited_from = "openai";
            api_key_name = "MISTRAL_DEVSTRAL_API_KEY";
            endpoint = "https://api.mistral.ai/v1";
            model = "devstral-latest";
            extra_request_body = {
              max_tokens = 4096;
            };
          };
          moonshot = {
            endpoint = "https://api.moonshot.ai/v1";
            model = "kimi-k2.5";
            extra_request_body = {
              temperature = 0.75;
              max_tokens = 32768;
            };
          };
        };
        behaviour = {
          auto_suggestions = true;
          minimize_diff = true;
          enable_fastapply = true;
        };
        mappings = {
          submit = {
            normal = "<CR>";
            insert = "<CR>";
          };
        };
      };
    };

    plugins.nui.enable = true;
    plugins.web-devicons.enable = true;
  };

  flake.modules.homeManager.dev =
    { config, ... }:
    {
      home = {
        sessionVariables = {
          ANTHROPIC_API_KEY = "$(cat ${config.programs.onepassword-secrets.secretPaths.anthropicApiKey})";
          MISTRAL_DEVSTRAL_API_KEY = "$(cat ${config.programs.onepassword-secrets.secretPaths.mistralDevstralApiKey})";
          MISTRAL_CODESTRAL_API_KEY = "$(cat ${config.programs.onepassword-secrets.secretPaths.mistralCodestralApiKey})";
          MOONSHOT_API_KEY = "$(cat ${config.programs.onepassword-secrets.secretPaths.moonshotApiKey})";
          MORPH_API_KEY = "$(cat ${config.programs.onepassword-secrets.secretPaths.morphApiKey})";
          TAVILY_API_KEY = "$(cat ${config.programs.onepassword-secrets.secretPaths.tavilyApiKey})";
        };
        shellAliases = {
          avante = ''nvim -c "lua vim.defer_fn(function()require(\"avante.api\").zen_mode()end, 100)"'';
        };
      };

      programs.onepassword-secrets.secrets = {
        anthropicApiKey = {
          path = ".secrets/.antropic_key";
          reference = "op://Development/Anthropic API Key/credential";
          group = "staff";
        };
        mistralDevstralApiKey = {
          path = ".secrets/.mistral_key";
          reference = "op://Development/Mistral API Key - Devstral/credential";
          group = "staff";
        };
        mistralCodestralApiKey = {
          path = ".secrets/.mistral_codestral_key";
          reference = "op://Development/Mistral API Key - Codestral/credential";
          group = "staff";
        };
        moonshotApiKey = {
          path = ".secrets/.moonshot_key";
          reference = "op://Development/Moonshot API Key/credential";
          group = "staff";
        };
        morphApiKey = {
          path = ".secrets/.morph_key";
          reference = "op://Development/MorphLLM API Key/credential";
          group = "staff";
        };
        tavilyApiKey = {
          path = ".secrets/.tavily_key";
          reference = "op://Development/Tavily API Key/credential";
          group = "staff";
        };
      };
    };
}
