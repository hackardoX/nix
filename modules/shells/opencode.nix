{ inputs, config, ... }:
{
  flake.modules.homeManager.dev =
    { pkgs, ... }:
    {
      programs.opencode = {
        enable = true;
        package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode2;
        settings = {
          autoupdate = false;
          # Last matching rule wins: broad rules first, exceptions after.
          permissions =
            let
              rule = action: effect: resource: { inherit action resource effect; };
              shell = rule "shell";
            in
            [
              (shell "ask" "*")
              (rule "edit" "ask" "*")

              (shell "allow" "ls *")
              (shell "allow" "cat *")
              (shell "allow" "grep *")
              (shell "allow" "npm *")

              # Read-only git and staging. Everything else (checkout, merge,
              # rebase, reset, ...) falls through to ask.
              (shell "allow" "git status *")
              (shell "allow" "git diff *")
              (shell "allow" "git log *")
              (shell "allow" "git show *")
              (shell "allow" "git blame *")
              (shell "allow" "git ls-files *")
              (shell "allow" "git rev-parse *")
              (shell "allow" "git branch --show-current")
              (shell "allow" "git add *")

              # Never pick "Allow always" here: it saves a durable allow rule.
              (shell "ask" "git commit *")
              (shell "ask" "git -C * commit *")

              (shell "deny" "rm *")
              (shell "deny" "git push *")
              (shell "deny" "git -C * push *")
              (shell "deny" "git -c * push *")
              (shell "deny" "gh pr merge *")
            ];
          # Hard deny, applied after agent rules and saved approvals, and
          # not overridable by project config.
          experimental.policies = [
            {
              action = "permission";
              resource = "shell:git push *";
              effect = "deny";
            }
            {
              action = "permission";
              resource = "shell:git -C * push *";
              effect = "deny";
            }
            {
              action = "permission";
              resource = "shell:git -c * push *";
              effect = "deny";
            }
            {
              action = "permission";
              resource = "shell:gh pr merge *";
              effect = "deny";
            }
          ];
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

      # opencode2 installs as bin/opencode2; keep the familiar command name.
      home.shellAliases.opencode = "opencode2";
    };
}
