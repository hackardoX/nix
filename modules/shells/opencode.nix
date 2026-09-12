{ config, ... }:
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
              baseURL = config.flake.meta.aiProviders.lumo.endpoint;
              apiKey = config.flake.meta.aiProviders.lumo.apiKeyEnv;
            };
            models = config.flake.meta.aiProviders.lumo.models;
          };
        };
      };
    };
  };
}
