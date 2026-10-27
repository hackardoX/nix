{ inputs, config, ... }:
{
  flake.modules.homeManager.opencode =
    { pkgs, ... }:
    {
      programs.opencode = {
        enable = true;
        package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode2;
        settings = {
          autoupdate = false;
          plugins = [ "@mohak34/opencode-notifier@latest" ];
          # Last matching rule wins: broad rules first, exceptions after.
          permissions = [
            {
              action = "shell";
              resource = "*";
              effect = "ask";
            }
            {
              action = "edit";
              resource = "*";
              effect = "ask";
            }

            {
              action = "shell";
              resource = "ls *";
              effect = "allow";
            }
            {
              action = "shell";
              resource = "cat *";
              effect = "allow";
            }
            {
              action = "shell";
              resource = "grep *";
              effect = "allow";
            }

            # Read-only git and staging. Everything else (checkout, merge,
            # rebase, reset, ...) falls through to ask.
            {
              action = "shell";
              resource = "git status *";
              effect = "allow";
            }
            {
              action = "shell";
              resource = "git diff *";
              effect = "allow";
            }
            {
              action = "shell";
              resource = "git log *";
              effect = "allow";
            }
            {
              action = "shell";
              resource = "git show *";
              effect = "allow";
            }
            {
              action = "shell";
              resource = "git blame *";
              effect = "allow";
            }

            {
              action = "shell";
              resource = "git ls-files *";
              effect = "allow";
            }
            {
              action = "shell";
              resource = "git rev-parse *";
              effect = "allow";
            }
            {
              action = "shell";
              resource = "git branch --show-current";
              effect = "allow";
            }
            {
              action = "shell";
              resource = "git add *";
              effect = "allow";
            }

            # Not a boundary (find -delete and scripts get around it), only a
            # prompt where uncommitted work could be lost.
            {
              action = "shell";
              resource = "rm *";
              effect = "ask";
            }
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
            {
              action = "permission";
              resource = "shell:npm publish *";
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

      # Read-only in the sandbox, so Nix owns it.
      xdg.configFile."opencode/opencode-notifier.json".text =
        let
          # OSC 9 via terminal stdout: no subprocess, so it works in the nono sandbox
          # (osascript and afplay may be blocked). Ghostty and macOS play the sound.
          loud = {
            sound = false;
            notification = true;
            command = false;
            bell = false;
          };
          quiet = {
            sound = false;
            notification = false;
            command = false;
            bell = false;
          };
        in
        builtins.toJSON {
          notificationSystem = "ghostty";
          sound = false;
          notification = true;
          suppressWhenFocused = true;
          events = {
            permission = loud;
            complete = loud;
            error = loud;
            question = loud;
            subagent_complete = quiet;
            user_cancelled = quiet;
            session_started = false;
            user_message = false;
            client_connected = false;
          };
        };
    };
}
