{
  flake.modules.homeManager.base = {
    programs.zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;

      options = [ "--cmd cd" ];
    };
  };
}
