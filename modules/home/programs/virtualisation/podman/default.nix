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
  cfg = config.${namespace}.programs.virtualisation.podman;
in
{
  options.${namespace}.programs.virtualisation.podman = {
    enable = mkEnableOption "podman";
    overrideDockerSocket = mkBoolOpt false "Whether or not to override the docker socket.";
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        podman
      ];

      file.".config/containers/containers.conf".text = ''
        [machine]
          rosetta=false
          provider = "applehv"
      '';

      activation = {
        setupPodman = home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          # add a check with podman machine list -q before proceeding
          # if it is empty, then init and start the machine
          echo "Activating podman..."
          # Loading home PATH to make podman available
          PATH="${config.home.path}/bin:$PATH"
          if [ -z "$($DRY_RUN_CMD podman machine list -q)" ]; then
            $DRY_RUN_CMD podman machine init
            $DRY_RUN_CMD podman machine start
            echo "Podman machine initialized and started"
          else
            echo "Podman machine already initialized and started"
          fi
        '';
      };

      sessionVariables = lib.mkIf cfg.overrideDockerSocket {
        DOCKER_HOST = "unix://$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}')";
      };
    };
  };
}
