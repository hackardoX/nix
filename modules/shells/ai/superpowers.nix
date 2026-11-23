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

      # OpenCode v2 derives the skill id from the directory name (frontmatter `name` is only a label),
      # so the prefix is a rename; Claude Code keeps the plain names.
      opencodeSkills = lib.mapAttrs' (name: lib.nameValuePair "superpowers:${name}") skills;

      instructions = worktreeSkill: ''
        # Superpowers skills

        - For worktrees use `workmux add <branch> -b`, never `git worktree add`. This overrides the `${worktreeSkill}` skill.
      '';
    in
    {
      config = lib.mkMerge [
        {
          programs.opencode.skills = opencodeSkills;
          xdg.configFile."opencode/AGENTS.md".text = instructions "superpowers:using-git-worktrees";
        }
        (lib.mkIf claudeCode.enable {
          programs.claude-code.skills = skills;
          xdg.stateFile."claude-code/CLAUDE.md".text = instructions "using-git-worktrees";
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
