{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.${namespace}.programs.containerization.docker;
in
{
  options.${namespace}.programs.containerization.docker = {
    enable = mkEnableOption "docker";
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        docker
      ];
    };
  };
}
