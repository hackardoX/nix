{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.programs.terminal.tools.carapace;
in
{
  options.${namespace}.programs.terminal.tools.carapace = {
    enable = lib.mkEnableOption "carapace";
  };

  config = mkIf cfg.enable {
    home = {
      # file = {
      #   "Library/Application Support/carapace/specs/ls.yaml".text = mkIf ezaCfg.enable ''
      #     # yaml-language-server: $schema=https://carapace.sh/schemas/command.json
      #     name: ls
      #     description: An alias for eza
      #     parsing: disabled
      #     completion:
      #       positionalany: ["$carapace.bridge.CarapaceBin([eza])"]
      #   '';
      #   "Library/Application Support/carapace/specs/cat.yaml".text = mkIf ezaCfg.enable ''
      #     # yaml-language-server: $schema=https://carapace.sh/schemas/command.json
      #     name: cat
      #     description: An alias for bat
      #     parsing: disabled
      #     completion:
      #       positionalany: ["$carapace.bridge.CarapaceBin([bat])"]
      #   '';
      # };

      sessionVariables = {
        # CARAPACE_LENIENT = 1;
        CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense";
      };
    };

    programs = {
      carapace = {
        enable = true;
        enableBashIntegration = true;
        # Done manually to avoid conflict with fzf-tab
        enableZshIntegration = false;
        enableFishIntegration = true;
      };

      # zsh.initContent =
      #   lib.mkOrder 450 # Bash
      #     ''
      #       source <(${config.programs.carapace.package}/bin/carapace _carapace zsh)
      #     '';
    };
  };
}
