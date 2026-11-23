{ inputs, config, ... }:
{
  flake.modules.homeManager.opencode =
    { pkgs, ... }:
    {
      # Read by the plugin from ~/.config/opencode (also in the sandbox, which can read it).
      # "ghostty" sends OSC 9 through the tty, which zellij forwards to Ghostty; the default
      # osascript popup would depend on the sandbox allowing it.
      xdg.configFile."opencode/opencode-notifier.json".text = builtins.toJSON {
        notificationSystem = "ghostty";
        suppressGhosttySound = true;
        suppressWhenFocused = false;
      };

      programs.opencode = {
        enable = true;
        mutableSettings = true;
        package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode2;
        settings = {
          autoupdate = false;
          # v2 key is `plugins`. Notifications come from this plugin: the built-in attention
          # alerts are skipped under zellij (it never answers OpenTUI's focus-reporting query,
          # so OpenCode's focus state stays unknown). The plugin checks the zellij pane itself.
          plugins = [ "@mohak34/opencode-notifier@latest" ];
          # Last matching rule wins: broad rules first, exceptions after.
          experimental = {
            schedules = true;
          };
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
          # not overridable by project config. `git push` is not listed: it
          # falls through to the global shell ask (unsandboxed), the sandbox
          # relaxes that to allow, and the git broker asks for each push.
          policies = [
            {
              action = "tool.use";
              resource = "shell:gh pr merge *";
              effect = "deny";
            }
            {
              action = "tool.use";
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
        cli = {
          tabs.mode = "off";
          prompt.image_preview = true;
          session.image_preview = true;
          attention = {
            notifications = true;
            sound = false;
          };
        };
      };
    };
}
