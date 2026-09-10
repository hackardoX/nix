{
  flake.modules.homeManager.dev = { pkgs, ... }: {
    home.packages = [
      (pkgs.writeShellScriptBin "dexec" ''
        exec ${pkgs.direnv}/bin/direnv exec . "$@"
      '')
    ];
    programs.direnv = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
      silent = true;
    };
  };
}
