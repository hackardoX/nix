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
  podmanSymLinkSocketPath = "/var/run/podman.sock";
in
{
  options.${namespace}.programs.containerization.podman = {
    enable = mkEnableOption "podman";
    autoStart = mkBoolOpt true "Whether or not to start the podman machine on startup.";
    rosetta = mkBoolOpt false "Whether or not to use rosetta.";
    aliasDocker = mkBoolOpt false "Whether or not to alias docker to podman.";
    overrideDockerSocket = mkBoolOpt false "Whether or not to override the docker socket.";
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        podman
      ];

      file.".config/containers/containers.conf".text = ''
        [machine]
          rosetta=${lib.boolToString cfg.rosetta}
          provider = "applehv"
      '';

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
            echo "Create docker socket symlink"
            run sudo ln -sf "$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}')" "${podmanSymLinkSocketPath}"
          else
            echo "Podman machine already initialized and started"
          fi
        '';
      };

      sessionVariables = lib.mkIf cfg.overrideDockerSocket {
        DOCKER_HOST = "unix://${podmanSymLinkSocketPath}";
      };

      shellAliases = lib.mkIf cfg.aliasDocker {
        docker = "podman";
      };
    };

    launchd.agents.podman = mkIf (pkgs.stdenv.isDarwin && cfg.autoStart) {
      enable = true;
      config = {
        Label = "com.github.podman";
        ProgramArguments = [
          "${lib.getExe pkgs.podman}"
          "machine"
          "start"
        ];
        RunAtLoad = true;
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/podman-helper/podman-helper.err.log";
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/podman-helper/podman-helper.out.log";
      };
    };
  };
  # // mkIf (!cfg.enable) {
  #   home.activation.cleanupPodman = home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  #     echo "Cleaning up podman..."
  #     # Remove the launchd agent configuration
  #     run launchctl unload "${config.home.homeDirectory}/Library/LaunchAgents/com.example.podman.plist"
  #     run rm -f "${config.home.homeDirectory}/Library/LaunchAgents/com.example.podman.plist"
  #     # Remove the docker socket symlink
  #     run sudo rm -f "${podmanSymLinkSocketPath}"
  #   '';
  # };
}
