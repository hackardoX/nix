{ inputs, ... }:
{
  flake.modules.homeManager.claude-code =
    hmArgs@{
      lib,
      options,
      pkgs,
      ...
    }:
    let
      claude = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;
    in
    {
      config = lib.mkMerge [
        {
          programs.claude-code = {
            enable = true;
            package = claude;
            enableMcpIntegration = true;
            configDir = "${hmArgs.config.xdg.stateHome}/claude-code";
            settings.skipDangerousModePermissionPrompt = true;
          };

          xdg.stateFile."claude-code/.keep".text = "";
          # Default so users without any MCP instruction modules still evaluate.
          xdg.stateFile."claude-code/CLAUDE.md".text = lib.mkDefault "";
          # Default so hosts without MCP servers still evaluate; Home Manager's own entry overrides it.
          home.file."${hmArgs.config.xdg.stateHome}/claude-code/skills/claude-code-home-manager".source =
            lib.mkDefault pkgs.emptyDirectory;

          # Requires ai/claude_api_key in the importing user's sops file (only secrets/users/aaccardo.yaml has it).
          sops.secrets."ai/claude_api_key" = { };
        }
        # optional integration: registers sandbox needs only when the nono feature is present
        (lib.optionalAttrs (options.programs ? nono) {
          programs.nono.harnesses.claude-code.env.CLAUDE_CODE_OAUTH_TOKEN =
            hmArgs.config.sops.placeholder."ai/claude_api_key";
        })
      ];
    };
}
