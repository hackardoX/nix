{
  flake.modules.homeManager.dev =
    { pkgs, ... }@hmArgs:
    {
      home = {
        sessionVariables = {
          ANTHROPIC_API_KEY = "$(cat ${hmArgs.config.programs.onepassword-secrets.secretPaths.mistralDevstralApiKey})";
          MISTRAL_CODESTRAL_API_KEY = "$(cat ${hmArgs.config.programs.onepassword-secrets.secretPaths.mistralCodestralApiKey})";
          MISTRAL_DEVSTRAL_API_KEY = "$(cat ${hmArgs.config.programs.onepassword-secrets.secretPaths.mistralDevstralApiKey})";
          MOONSHOT_API_KEY = "$(cat ${hmArgs.config.programs.onepassword-secrets.secretPaths.moonshotApiKey})";
          MORPH_API_KEY = "$(cat ${hmArgs.config.programs.onepassword-secrets.secretPaths.morphApiKey})";
          TAVILY_API_KEY = "$(cat ${hmArgs.config.programs.onepassword-secrets.secretPaths.tavilyApiKey})";
        };
      };

      programs.opencode = {
        enable = true;
        settings = {
          model = "mistral-devstral/devstral-latest";
          autoupdate = false;
          provider = {
            # anthropic = {
            #   options = {
            #     apiKey = "{env:ANTHROPIC_API_KEY}";
            #   };
            # };
            # moonshot = {
            #   options = {
            #     apiKey = "{env:MOONSHOT_API_KEY}";
            #   };
            # };
            # morph = {
            #   options = {
            #     apiKey = "{env:MORPH_API_KEY}";
            #   };
            # };

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
            mistral-codestral = {
              npm = "@ai-sdk/mistral";
              name = "Mistral Codestral";
              options = {
                baseURL = "https://codestral.mistral.ai/v1";
                apiKey = "{env:MISTRAL_CODESTRAL_API_KEY}";
              };
              models = {
                "codestral-latest" = {
                  name = "Codestral Latest";
                  limit = {
                    context = 256000;
                    output = 4096;
                  };
                };
              };
            };

          };
        };
        skills =
          let
            mattpocock-skills = pkgs.fetchFromGitHub {
              owner = "mattpocock";
              repo = "skills";
              rev = "main"; # pin to a commit hash for reproducibility
              hash = "sha256-kInYwg1xaBrcW6lZXm2AuyHKZ9gjL6qGvoope+25ADs=";
            };
            mkSkill = skill: builtins.readFile "${mattpocock-skills}/${skill}/SKILL.md";
            mkSkills =
              skills:
              builtins.listToAttrs (
                map (skill: {
                  name = skill;
                  value = mkSkill skill;
                }) skills
              );
          in
          mkSkills [
            "prd-to-plan"
            "write-a-prd"
            "prd-to-issues"
            "grill-me"
            "design-an-interface"
            "request-refactor-plan"
          ];
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
