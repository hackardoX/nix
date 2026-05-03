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
              "rm *" = "deny";
              "grep *" = "allow";
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
        skills =
          let
            mattpocock-skills = pkgs.fetchFromGitHub {
              owner = "mattpocock";
              repo = "skills";
              rev = "main";
              hash = "sha256-qOhU5bBnT6kI8c7i0r0IyecrgLJNNPlmQtAb6qWM73Q=";
            };
            findFile =
              root: target:
              let
                entries = builtins.readDir root;
                found = lib.filterAttrs (name: _: name == target) entries;
                subdirs = builtins.attrNames (lib.filterAttrs (_: v: v == "directory") entries);
                recurse = builtins.filter (x: x != null) (map (dir: findFile "${root}/${dir}" target) subdirs);
              in
              if found != { } then
                "${root}/${target}"
              else if recurse != [ ] then
                builtins.head recurse
              else
                null;

            mkSkill =
              skill:
              let
                path = findFile mattpocock-skills skill;
              in
              if path == null then throw "Skill '${skill}' not found" else builtins.readFile "${path}/SKILL.md";

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
            "grill-with-docs"
            "caveman"
            "tdd"
            "to-issues"
            "to-prd"
            "diagnose"
            "zoom-out"
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
