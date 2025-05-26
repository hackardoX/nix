{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.programs.terminal.tools.comma;
in
{
  options.${namespace}.programs.terminal.tools.comma = {
    enable = lib.mkEnableOption "comma";
  };

  config = mkIf cfg.enable {
    programs = {
      nix-index-database.comma.enable = true;

      nix-index = {
        enable = true;
        package = pkgs.nix-index;

        enableZshIntegration = true;

        # link nix-index database to ~/.cache/nix-index
        symlinkToCacheHome = true;
      };
    };
  };
}
