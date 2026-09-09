{
  flake.modules.homeManager.dev = {
    programs.opencode = {
      enable = true;
      settings = {
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
          proton-lumo = {
            npm = "@ai-sdk/openai-compatible";
            name = "Proton Lumo";
            options = {
              baseURL = "https://lumo.proton.me/api/ai/v1";
              apiKey = "LUMO_API_KEY";
            };
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
        };
      };
    };
  };
}
