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

    # launchd.agents.docker = mkIf (pkgs.stdenv.isDarwin && cfg.autoStart) {
    #   enable = true;
    #   config = {
    #     Label = "com.github.docker";
    #     ProgramArguments = [
    #       "${lib.getExe pkgs.docker}"
    #       "machine"
    #       "start"
    #     ];
    #     RunAtLoad = true;
    #     StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/docker-helper/docker-helper.err.log";
    #     StandardOutPath = "${config.home.homeDirectory}/Library/Logs/docker-helper/docker-helper.out.log";
    #   };
    # };
  };
  # // mkIf (!cfg.enable) {
  #   home.activation.cleanupDocker = home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  #     # TODO
  #   '';
  # };
}
