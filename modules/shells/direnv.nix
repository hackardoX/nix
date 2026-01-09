{
  flake.modules.homeManager.base = {

    programs.direnv = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
      silent = true;
    };
  };
}
