{
  flake.modules.homeManager.base = {
    # home = {
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

    # sessionVariables = {
    # CARAPACE_LENIENT = 1;
    # CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense";
    # };
    # };

    programs = {
      carapace = {
        enable = false;
        enableBashIntegration = true;
        enableZshIntegration = true;
        enableFishIntegration = true;
      };
    };
  };
}
