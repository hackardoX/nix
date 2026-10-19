{
  flake.modules.homeManager.dev =
    hmArgs@{ lib, pkgs, ... }:
    {
      config = lib.mkMerge [
        {
          programs.nono.harnesses.claude-code = {
            alias = "claude";
            description = "Claude Code agent sandbox";
            command = lib.getExe hmArgs.config.programs.claude-code.finalPackage;
            env = {
              CLAUDE_CONFIG_DIR = "$XDG_STATE_HOME/claude-code-sandbox";
              GLAB_CONFIG_DIR = "$XDG_STATE_HOME/claude-code-sandbox/glab";
              DISABLE_AUTOUPDATER = "1";
              CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
            };
            allow = [ "$XDG_STATE_HOME/claude-code-sandbox" ];
            domains = [ "api.anthropic.com" ];
          };

          home.shellAliases.claude-unsandboxed = lib.getExe hmArgs.config.programs.claude-code.finalPackage;

          xdg.stateFile."claude-code-sandbox/CLAUDE.md".source =
            hmArgs.config.xdg.stateFile."claude-code/CLAUDE.md".source;
          xdg.stateFile."claude-code-sandbox/settings.json".source =
            pkgs.runCommand "claude-code-sandbox-settings.json" { nativeBuildInputs = [ pkgs.jq ]; }
              ''
                jq '. * {permissions: {defaultMode: "bypassPermissions"}, skipDangerousModePermissionPrompt: true}' \
                  ${
                    hmArgs.config.home.file."${hmArgs.config.xdg.stateHome}/claude-code/settings.json".source
                  } > $out
              '';
          xdg.stateFile."claude-code-sandbox/skills/claude-code-home-manager".source =
            hmArgs.config.home.file."${hmArgs.config.xdg.stateHome}/claude-code/skills/claude-code-home-manager".source;
        }
      ];
    };
}
