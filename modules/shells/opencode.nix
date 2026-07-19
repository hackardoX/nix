{ lib, ... }:
let
  models = {
    devstral = "mistral-devstral/devstral-latest";
    "qwen3.6" = "qwen/qwen3.6-plus";
  };
in
{
  flake.modules.homeManager.dev =
    { pkgs, ... }@hmArgs:
    {
      home = {
        sessionVariables = {
          OPENCODE_ENABLE_EXA = true; # Enable websearch tool
          ANTHROPIC_API_KEY = "$(cat ${hmArgs.config.programs.onepassword-secrets.secretPaths.mistralDevstralApiKey})";
          MISTRAL_DEVSTRAL_API_KEY = "$(cat ${hmArgs.config.programs.onepassword-secrets.secretPaths.mistralDevstralApiKey})";
          OPENCODE_API_KEY = "$(cat ${hmArgs.config.programs.onepassword-secrets.secretPaths.opencodeZenApiKey})";
          MOONSHOT_API_KEY = "$(cat ${hmArgs.config.programs.onepassword-secrets.secretPaths.moonshotApiKey})";
          MORPH_API_KEY = "$(cat ${hmArgs.config.programs.onepassword-secrets.secretPaths.morphApiKey})";
          TAVILY_API_KEY = "$(cat ${hmArgs.config.programs.onepassword-secrets.secretPaths.tavilyApiKey})";
        };
      };

      programs.opencode = {
        enable = true;
        settings = {
          model = models."qwen3.6";
          autoupdate = false;
          permission = {
            "bash" = {
              "*" = "ask";
              "git *" = "allow";
              "npm *" = "allow";
              "ls *" = "allow";
              "cat *" = "allow";
              "grep *" = "allow";
              "rm *" = "deny";
            };
            edit = "ask";
          };
          provider = {
            # Custom providers
            mistral-devstral = {
              npm = "@ai-sdk/mistral";
              name = "Mistral Devstral";
              options = {
                baseURL = "https://api.mistral.ai/v1";
                apiKey = "{env:MISTRAL_DEVSTRAL_API_KEY}";
              };
              models = {
                "devstral-latest" = {
                  name = "Devstral Latest";
                  limit = {
                    context = 131072;
                    output = 4096;
                  };
                };
              };
            };
          };
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
        opencodeZenApiKey = {
          path = ".secrets/.opencode_zen_key";
          reference = "op://Development/Opencode Zen API Key/credential";
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
