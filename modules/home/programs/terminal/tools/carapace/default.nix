{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.programs.terminal.tools.carapace;
  ezaCfg = config.${namespace}.programs.terminal.tools.eza;
in
{
  options.${namespace}.programs.terminal.tools.carapace = {
    enable = lib.mkEnableOption "carapace";
  };

  config = mkIf cfg.enable {
    home = {
      file."Library/Application Support/carapace/specs/ls.yaml".text = mkIf ezaCfg.enable ''
        # yaml-language-server: $schema=https://carapace.sh/schemas/command.json
        name: ls
        run: "[eza]"
      '';

      sessionVariables = {
        # CARAPACE_LENIENT = 1;
        CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense";
      };
    };

    programs = {
      carapace = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        enableFishIntegration = true;
      };

      zsh.initContent = # Bash
        ''
          export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
          # zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
          # zstyle ':completion:*:git:*' group-order 'main commands' 'alias commands' 'external commands'

          # Disable problematic carapace features that conflict with fzf-tab
          zstyle ':completion:*' file-patterns '%p(^-/):globbed-files' '^(-/):directories' '%p:all-files'

          # Better handling of carapace descriptions
          zstyle ':fzf-tab:complete:*:*' fzf-preview 'echo $word'
          zstyle ':fzf-tab:complete:*:descriptions' fzf-preview 'echo $word'
        '';
    };
  };
}
