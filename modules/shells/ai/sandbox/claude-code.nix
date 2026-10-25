{
  flake.modules.homeManager.nono =
    hmArgs@{ lib, pkgs, ... }:
    let
      claudeCode = hmArgs.config.programs.claude-code;
    in
    {
      # Sandboxed Claude exists only when the claude-code feature is present. It also needs the
      # claude-code settings.json (home.file) that the jq derivation below copies.
      config = lib.mkIf claudeCode.enable {
        programs.nono.harnesses.claude-code = {
          alias = "claude";
          description = "Claude Code agent sandbox";
          command = lib.getExe claudeCode.finalPackage;
          env = {
            CLAUDE_CONFIG_DIR = "$XDG_STATE_HOME/claude-code-sandbox";
            DISABLE_AUTOUPDATER = "1";
            CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
          };
          allow = [ "$XDG_STATE_HOME/claude-code-sandbox" ];
          domains = [ "api.anthropic.com" ];
        };

        home.shellAliases.claude-unsandboxed = lib.getExe claudeCode.finalPackage;

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
      };
    };
}
