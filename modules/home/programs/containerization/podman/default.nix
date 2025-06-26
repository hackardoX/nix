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
  inherit (lib.${namespace}) mkBoolOpt;
  inherit (inputs) home-manager;
  cfg = config.${namespace}.programs.containerization.podman;
in
{
  options.${namespace}.programs.containerization.podman = {
    enable = mkEnableOption "podman";
    rosetta = mkBoolOpt false "Whether or not to use rosetta.";
    aliasDocker = mkBoolOpt false "Whether or not to alias docker to podman.";
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        podman
      ];

      file = {
        ".config/containers/containers.conf".text = ''
          [machine]
            rosetta=${lib.boolToString cfg.rosetta}
            provider = "applehv"
        '';
      };

      activation = {
        setupPodman = home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          # add a check with podman machine list -q before proceeding
          # if it is empty, then init and start the machine
          echo "Activating podman..."
          # Loading home PATH to make podman available
          PATH="${config.home.path}/bin:$PATH"
          if [ -z "$(podman machine list -q)" ]; then
            run podman machine init
            echo "Podman machine initialized"
          else
            echo "Podman machine already initialized and started"
          fi
        '';
      };

      shellAliases = lib.mkIf cfg.aliasDocker {
        docker = "podman";
      };
    };
  };
}
