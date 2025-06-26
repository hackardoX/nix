{
  config,
  inputs,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (inputs) home-manager;
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

      activation = {
        setupDocker = home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          # TODO
        '';
      };

    };
  };
}
