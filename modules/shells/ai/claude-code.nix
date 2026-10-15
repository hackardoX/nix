{ inputs, ... }:
{
  flake.modules.homeManager.dev =
    hmArgs@{ pkgs, ... }:
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
      };
    };

  flake.modules.homeManager.aaccardo = hmArgs: {
    sops.secrets."ai/claude_api_key" = { };
    programs.claude-code.sandbox.env.CLAUDE_CODE_OAUTH_TOKEN =
      hmArgs.config.sops.placeholder."ai/claude_api_key";
  };
}
