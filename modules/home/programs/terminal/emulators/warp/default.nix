{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.programs.terminal.emulators.warp;
in
{
  options.${namespace}.programs.terminal.emulators.warp = {
    enable = mkEnableOption "warp";
    default = mkBoolOpt false "Whether to set Warp as the session EDITOR";
  };

  config = mkIf cfg.enable {
    home = {
      sessionVariables = {
        EDITOR = mkIf cfg.default "warp";
      };
    };

    targets.darwin.defaults = {
      dev.warp.Warp-Stable = {
        AddedSubshellCommands = ''[\\"nix develop\\"]'';
        AliasExpansionBannerSeen = "true";
        AliasExpansionEnabled = "true";
        AutocompleteSymbols = "false";
        Notifications = ''"{\\"mode\\":\\"Enabled\\",\\"is_long_running_enabled\\":true,\\"long_running_threshold\\":{\\"secs\\":30,\\"nanos\\":0},\\"is_password_prompt_enabled\\":true}"'';
        TelemetryEnabled = "false";
        UseSshTmuxWrapper = true;
      };
    };

    programs.zsh.initContent = lib.mkAfter ''
      # Auto-Warpify
      [[ "$-" == *i* ]] && printf 'P$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "zsh", "uname": "Darwin" }}�'
    '';

    programs.bash.initExtra = lib.mkAfter ''
      # Auto-Warpify
      [[ "$-" == *i* ]] && printf 'P$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "bash", "uname": "Darwin" }}ú'
    '';
  };
}
