{
  inputs,
  lib,
  ...
}:
{
  flake.modules.homeManager.base =
    { config, pkgs, ... }:
    let
      machineName = "podman-machine-default"; # Don't leave empty!
      podmanSymLinkSocketPath = "${config.home.homeDirectory}/.local/share/containers/podman/machine/podman.sock";
      mkOptFlag = n: v: "--${n} ${lib.escapeShellArg (toString v)}";
      mkOptList = n: vs: lib.concatStringsSep " " (map (v: "--${n} ${lib.escapeShellArg v}") vs);
      mkInitFlags =
        settings:
        lib.concatStringsSep " " (
          lib.flatten [
            (lib.optional (settings.cpus != null) (mkOptFlag "cpus" "${toString settings.cpus}"))
            (lib.optional (settings.diskSize != null) (mkOptFlag "disk-size" "${toString settings.diskSize}"))
            (lib.optional (settings.memory != null) (mkOptFlag "memory" "${toString settings.memory}"))
            (lib.optional (settings.volume != [ ]) (mkOptList "volume" settings.volume))
            (lib.optional (settings.imagePath != "") (mkOptFlag "image" settings.imagePath))
            (lib.optional (settings.ignitionPath != "") (mkOptFlag "ignition-path" settings.ignitionPath))
            (lib.optional settings.now "--now")
            (lib.optional (settings.timezone != "") (mkOptFlag "timezone" settings.timezone))
            (lib.optional settings.rootful "--rootful")
            (lib.optional (settings.username != "") (mkOptFlag "username" settings.username))
            (lib.optional (!settings.userModeNetworking) "--no-user-mode-networking")
          ]
        );
    in
    {
      options.podman = {
        currentSocket = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          description = "Path to the current podman machine socket";
          default = podmanSymLinkSocketPath;
        };
        machine = lib.mkOption {
          type = lib.types.submodule {
            options = {
              enable = lib.mkEnableOption "podman-machine";
              name = lib.mkOption {
                type = lib.types.str;
                default = "podman-machine-default";
                description = "The name of the podman machine.";
              };
              settings = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    cpus = lib.mkOption {
                      type = lib.types.nullOr lib.types.int;
                      default = null;
                      description = "Number of CPUs to allocate to the VM.";
                    };
                    diskSize = lib.mkOption {
                      type = lib.types.nullOr lib.types.int;
                      default = null;
                      description = "Disk size (in GB) to allocate to the VM.";
                    };
                    memory = lib.mkOption {
                      type = lib.types.nullOr lib.types.int;
                      default = null;
                      description = "Memory (in MB) to allocate to the VM.";
                    };
                    volume = lib.mkOption {
                      type = lib.types.listOf lib.types.str;
                      default = [ ];
                      description = "Bind mount volumes into the VM.";
                    };
                    imagePath = lib.mkOption {
                      type = lib.types.str;
                      default = "";
                      description = "Path to the OS image to use.";
                    };
                    ignitionPath = lib.mkOption {
                      type = lib.types.str;
                      default = "";
                      description = "Path to a custom Ignition file.";
                    };
                    now = lib.mkOption {
                      type = lib.types.bool;
                      default = true;
                      description = "Start the VM immediately after init.";
                    };
                    timezone = lib.mkOption {
                      type = lib.types.str;
                      default = "";
                      description = "Set the VM timezone.";
                    };
                    rootful = lib.mkOption {
                      type = lib.types.bool;
                      default = false;
                      description = "Enable rootful mode.";
                    };
                    username = lib.mkOption {
                      type = lib.types.str;
                      default = "";
                      description = "Username inside the VM (default core).";
                    };
                    userModeNetworking = lib.mkOption {
                      type = lib.types.bool;
                      default = true;
                      description = "Enable user-mode networking (default true).";
                    };
                  };
                };
                default = { };
                description = "Podman machine settings";
              };
            };
          };
          default = { };
          description = "Podman machine";
        };
      };

      config = lib.mkIf (pkgs.stdenv.hostPlatform.isDarwin && config.podman.machine.enable) {
        podman.machine = {
          enable = lib.mkDefault true;
          name = "podman-machine-default";
          settings = {
            diskSize = lib.mkDefault 30;
            memory = lib.mkDefault 6144;
          };
        };

        home = {
          packages = with pkgs; [ podman ];

          file.".config/containers/containers.conf".text = ''
            [machine]
              rosetta=false
              provider="applehv"
          '';

          activation.podman-init =
            let
              podmanMachineSettings = config.podman.machine.settings;
              settingsHash = builtins.hashString "sha256" (builtins.toJSON podmanMachineSettings);
            in
            inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              PATH=${pkgs.openssh}/bin:${pkgs.podman}/bin:$PATH
              STATE_DIR="${config.home.homeDirectory}/.local/state/podman"
              mkdir -p "$STATE_DIR"
              HASH_FILE="$STATE_DIR/${machineName}.hash"

              CURRENT_HASH="${settingsHash}"

              if [ ! -f "$HASH_FILE" ]; then
                echo "No previous podman machine state found, initializing..."
                ${pkgs.podman}/bin/podman machine init ${mkInitFlags podmanMachineSettings} ${machineName}
                echo "$CURRENT_HASH" > "$HASH_FILE"
                exit 0
              fi

              if ! ${pkgs.podman}/bin/podman machine ls --format "{{.Name}}" | grep -q "^${machineName}\*\?$"; then
                echo "Podman machine ${machineName} does not exist, re-initializing..."
                ${pkgs.podman}/bin/podman machine init ${mkInitFlags podmanMachineSettings} ${machineName}
                echo "$CURRENT_HASH" > "$HASH_FILE"
                exit 0
              fi

              OLD_HASH=$(cat "$HASH_FILE")
              if [ "$OLD_HASH" != "$CURRENT_HASH" ]; then
                echo "Podman machine settings changed. Re-initializing ${machineName}..."
                ${pkgs.podman}/bin/podman machine rm -f ${machineName} || true
                ${pkgs.podman}/bin/podman machine init ${mkInitFlags podmanMachineSettings} ${machineName}
                echo "$CURRENT_HASH" > "$HASH_FILE"
                exit 0
              fi

              echo "Podman machine ${machineName} is up-to-date."

              echo "Updating podman socket symlink..."
              ACTUAL_SOCKET_PATH=$(${pkgs.podman}/bin/podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' ${machineName} 2>/dev/null || echo "")
              if [ -n "$ACTUAL_SOCKET_PATH" ] && [ -S "$ACTUAL_SOCKET_PATH" ]; then
                mkdir -p "$(dirname "${podmanSymLinkSocketPath}")"
                rm -f "${podmanSymLinkSocketPath}"
                ln -fs "$ACTUAL_SOCKET_PATH" "${podmanSymLinkSocketPath}"
                echo "Symlink updated: ${podmanSymLinkSocketPath} -> $ACTUAL_SOCKET_PATH"
              else
                echo "Warning: Could not find valid socket path for ${machineName}"
              fi
            '';

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
                            PODMAN_SOCKET_PATH=$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' ${machineName} 2>/dev/null || echo "")
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
                  StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/podman/${podmanLinkName}.err.log";
                  StandardOutPath = "${config.home.homeDirectory}/Library/Logs/podman/${podmanLinkName}.out.log";
                };
              };
            };
        };
      };
    };
}
