{
  flake.modules.homeManager.shell = {
    programs.zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      options = [ "--cmd cd" ];
    };
  };
}
