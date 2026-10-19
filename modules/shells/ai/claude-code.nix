{ inputs, ... }:
{
  flake.modules.homeManager.dev =
    hmArgs@{ lib, pkgs, ... }:
    let
      claude = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;
    in
    {
      config = {
        programs.claude-code = {
          enable = true;
          package = claude;
          enableMcpIntegration = true;
          configDir = "${hmArgs.config.xdg.stateHome}/claude-code";
          settings.skipDangerousModePermissionPrompt = true;
        };

        xdg.stateFile."claude-code/.keep".text = "";
        # Default so hosts without aaccardo-bucket instruction modules still evaluate.
        xdg.stateFile."claude-code/CLAUDE.md".text = lib.mkDefault "";
        # Default so hosts without MCP servers still evaluate; Home Manager's own entry overrides it.
        home.file."${hmArgs.config.xdg.stateHome}/claude-code/skills/claude-code-home-manager".source =
          lib.mkDefault pkgs.emptyDirectory;
      };
    };

  flake.modules.homeManager.aaccardo = hmArgs: {
    sops.secrets."ai/claude_api_key" = { };
    programs.nono.harnesses.claude-code.env.CLAUDE_CODE_OAUTH_TOKEN =
      hmArgs.config.sops.placeholder."ai/claude_api_key";
  };
}
