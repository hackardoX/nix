{
  flake.modules.homeManager.dev =
    hmArgs@{ pkgs, ... }:
    let
      podmanMachineName = "dev";
      podmanSymLinkSocketPath = "${hmArgs.config.home.homeDirectory}/.local/share/containers/podman/machine/podman.sock";
    in
    {
      home = {
        # file.".config/containers/containers.conf".text = ''
        #   [machine]
        #     rosetta=false
        #     provider="applehv"
        # '';
        packages = with pkgs; [
          docker
          docker-compose
          podman-compose
        ];
      };
      services.podman = {
        enable = true;
        useDefaultMachine = false;
        machines.${podmanMachineName} = {
          diskSize = 30;
          memory = 8192;
          volumes = [
            "${hmArgs.config.home.homeDirectory}:${hmArgs.config.home.homeDirectory}"
          ];
        };
      };
      programs.docker-cli = {
        enable = true;
        contexts = {
          podman = {
            Metadata.Description = "Podman machine";
            Endpoints.docker.Host = "unix://${podmanSymLinkSocketPath}";
          };
        };
        settings = {
          currentContext = "podman";
        };
      };
      launchd.agents =
        let
          podmanLinkName = "podman-link";
        in
        {
          ${podmanLinkName} = {
            enable = true;
            config = {
              ProgramArguments = [
                "${
                  pkgs.writeShellApplication {
                    name = podmanLinkName;
                    runtimeInputs = [ pkgs.podman ];
                    text = ''
                      echo "Starting podman socket symlink service..."

                      update_symlink() {
                        PODMAN_SOCKET_PATH=$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' ${podmanMachineName} 2>/dev/null || echo "")
                        if [ -n "$PODMAN_SOCKET_PATH" ] && [ -S "$PODMAN_SOCKET_PATH" ]; then
                          mkdir -p "$(dirname "${podmanSymLinkSocketPath}")"
                          if [ ! -L "${podmanSymLinkSocketPath}" ] || [ "$(readlink "${podmanSymLinkSocketPath}")" != "$PODMAN_SOCKET_PATH" ]; then
                            rm -f "${podmanSymLinkSocketPath}"
                            ln -fs "$PODMAN_SOCKET_PATH" "${podmanSymLinkSocketPath}"
                            echo "Symlink updated: ${podmanSymLinkSocketPath} -> $PODMAN_SOCKET_PATH"
                          fi
                          return 0
                        else
                          echo "Podman socket not found or not accessible"
                          return 1
                        fi
                      }

                      update_symlink

                      while true; do
                        sleep 30
                        update_symlink || echo "Failed to update symlink, will retry..."
                      done
                    '';
                  }
                }/bin/${podmanLinkName}"
              ];
              RunAtLoad = true;
              KeepAlive = true;
              StandardErrorPath = "${hmArgs.config.home.homeDirectory}/Library/Logs/podman/${podmanLinkName}.err.log";
              StandardOutPath = "${hmArgs.config.home.homeDirectory}/Library/Logs/podman/${podmanLinkName}.out.log";
            };
          };
        };
    };
}
