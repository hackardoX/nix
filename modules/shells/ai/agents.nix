{
  flake.modules.homeManager.ai-agents = {
    programs.opencode.settings = {
      default_agent = "main";

      agents = {
        build = {
          disabled = true;
        };
        plan = {
          disabled = true;
        };
        main = {
          description = "Plans, implements, verifies and reviews changes";
          mode = "primary";
          color = "#7aa2f7";
          system = builtins.readFile ./agents/main.md;
          permissions = [
            {
              action = "subagent";
              resource = "*";
              effect = "deny";
            }
            {
              action = "subagent";
              resource = "explore";
              effect = "allow";
            }

            # No shell deny here: the global shell asks apply (the sandbox relaxes
            # them to allow, and nono is the boundary). The rules below are the
            # exceptions.

            # Commits inside the sandbox are not prompted; only commit when the
            # user asks.
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

            # Ask in unsandboxed OpenCode, since workmux would open windows outside
            # the sandbox. The sandbox relaxes shell asks to allow. Its workmux
            # command is brokered and can reach zellij (modules/shells/workmux.nix).
            {
              action = "shell";
              resource = "workmux *";
              effect = "ask";
            }

            # worktree, merge and coordinator open multiplexer windows (the sandbox
            # has no multiplexer access, by design); open-pr needs gh. main calls
            # the workmux CLI directly instead.
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
      };
    };
  };
}
