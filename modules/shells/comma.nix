{ inputs, ... }:
{
  flake.modules.homeManager.dev = {
    imports = [ inputs.nix-index-database.homeModules.nix-index ];
    programs = {
      nix-index = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        symlinkToCacheHome = true;
      };
      nix-index-database.comma.enable = true;
    };
  };
}
