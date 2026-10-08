{
  flake.modules.homeManager.dev =
    let
      readOnlyShell = [
        {
          action = "shell";
          resource = "*";
          effect = "deny";
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
        {
          action = "shell";
          resource = "rg *";
          effect = "allow";
        }
        {
          action = "shell";
          resource = "head *";
          effect = "allow";
        }
        {
          action = "shell";
          resource = "tail *";
          effect = "allow";
        }
        {
          action = "shell";
          resource = "wc *";
          effect = "allow";
        }

        # Asks, because unsandboxed OpenCode would run the real glab with your
        # own token. The sandbox's glab is read-only (see sandbox.nix).
        {
          action = "shell";
          resource = "glab *";
          effect = "ask";
        }
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
      ];
    in
    {
      programs.opencode.settings = {
        default_agent = "orchestrator";

        # Models are intentionally not set: subagents inherit the session's
        # model, and each user can pin one per role with
        # programs.opencode.settings.agents.<role>.model.
        agents = {
          build = {
            disabled = true;
          };
          plan = {
            disabled = true;
          };
          orchestrator = {
            description = "Triages the task and delegates to specialist subagents";
            mode = "primary";
            color = "#7aa2f7";
            system = builtins.readFile ./agents/orchestrator.md;
            permissions = [
              {
                action = "subagent";
                resource = "*";
                effect = "deny";
              }
              {
                action = "subagent";
                resource = "architect";
                effect = "allow";
              }
              # Safeguard: the plan gate is a prompt rule, so every dev call
              # asks. Inside a linked worktree the wrapper passes --auto.
              {
                action = "subagent";
                resource = "dev";
                effect = "ask";
              }
              {
                action = "subagent";
                resource = "qa";
                effect = "allow";
              }
              {
                action = "subagent";
                resource = "security";
                effect = "allow";
              }
              {
                action = "subagent";
                resource = "explore";
                effect = "allow";
              }

              # Plans are the only thing the orchestrator writes.
              {
                action = "edit";
                resource = "*";
                effect = "deny";
              }
              {
                action = "external_directory";
                resource = "~/.opencode/plan/*";
                effect = "allow";
              }
              {
                action = "edit";
                resource = "~/.opencode/plan/*";
                effect = "allow";
              }
            ]
            ++ readOnlyShell
            ++ [
              # Commits still need the user's approval in the terminal (nono).
              {
                action = "shell";
                resource = "git add *";
                effect = "allow";
              }
              {
                action = "shell";
                resource = "git commit *";
                effect = "allow";
              }

              # These run workmux or gh, which cannot work from inside the
              # sandbox. The user runs workmux from a terminal outside it.
              {
                action = "skill";
                resource = "worktree";
                effect = "deny";
              }
              {
                action = "skill";
                resource = "merge";
                effect = "deny";
              }
              {
                action = "skill";
                resource = "coordinator";
                effect = "deny";
              }
              {
                action = "skill";
                resource = "open-pr";
                effect = "deny";
              }
            ];
          };

          architect = {
            description = "Read-only design and planning for ambiguous, cross-cutting or high-impact changes. Returns a plan, never code.";
            mode = "subagent";
            color = "#bb9af7";
            system = builtins.readFile ./agents/architect.md;
            permissions = [
              {
                action = "subagent";
                resource = "*";
                effect = "deny";
              }
              {
                action = "edit";
                resource = "*";
                effect = "deny";
              }
            ]
            ++ readOnlyShell;
          };

          dev = {
            description = "Implements a well-scoped change from a clear brief or plan, with focused diffs and local verification";
            mode = "subagent";
            color = "#9ece6a";
            system = builtins.readFile ./agents/dev.md;
            permissions = [
              {
                action = "subagent";
                resource = "*";
                effect = "deny";
              }
            ];
          };

          qa = {
            description = "Runs the project's checks, writes or fixes tests only, and reports pass/fail with evidence. Never edits production code.";
            mode = "subagent";
            color = "#e0af68";
            system = builtins.readFile ./agents/qa.md;
            permissions = [
              {
                action = "subagent";
                resource = "*";
                effect = "deny";
              }
              {
                action = "edit";
                resource = "*";
                effect = "deny";
              }
              {
                action = "edit";
                resource = "*test*";
                effect = "ask";
              }
              {
                action = "edit";
                resource = "*spec*";
                effect = "ask";
              }
              {
                action = "edit";
                resource = "*fixture*";
                effect = "ask";
              }
            ];
          };

          security = {
            description = "Read-only security review of a change: vulnerabilities, secrets, risky dependencies and CI or infra permissions";
            mode = "subagent";
            color = "#f7768e";
            system = builtins.readFile ./agents/security.md;
            permissions = [
              {
                action = "subagent";
                resource = "*";
                effect = "deny";
              }
              {
                action = "edit";
                resource = "*";
                effect = "deny";
              }
            ]
            ++ readOnlyShell;
          };
        };
      };
    };
}
