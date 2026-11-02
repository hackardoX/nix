{ inputs, ... }:
{
  flake.modules.homeManager.superpowers =
    hmArgs@{ lib, options, ... }:
    let
      claudeCode = hmArgs.config.programs.claude-code;
      skillsRoot = "${inputs.superpowers}/skills";

      skills = lib.mapAttrs (name: _: "${skillsRoot}/${name}") (
        lib.filterAttrs (name: type: type == "directory" && !lib.hasPrefix "." name) (
          builtins.readDir skillsRoot
        )
      );

      instructions = ''
        # Superpowers skills

        - For worktrees use `workmux add <branch> -b`, never `git worktree add`. This overrides the `using-git-worktrees` skill.
      '';
    in
    {
      config = lib.mkMerge [
        {
          programs.opencode.skills = skills;
          xdg.configFile."opencode/AGENTS.md".text = instructions;
        }
        (lib.mkIf claudeCode.enable {
          programs.claude-code.skills = skills;
          xdg.stateFile."claude-code/CLAUDE.md".text = instructions;
        })
        # optional integration: the sandbox uses its own CLAUDE_CONFIG_DIR, so it needs its own links
        (lib.optionalAttrs (options.programs ? nono) (
          lib.mkIf claudeCode.enable {
            xdg.stateFile = lib.mapAttrs' (
              name: source:
              lib.nameValuePair "claude-code-sandbox/skills/${name}" {
                inherit source;
                recursive = true;
              }
            ) skills;
          }
        ))
      ];
    };
}
