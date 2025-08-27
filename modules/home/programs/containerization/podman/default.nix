{
  config,
  inputs,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    types
    ;
  inherit (lib.${namespace})
    mkBoolOpt
    mkOpt
    mkOpt'
    mkOptFlag
    mkOptList
    ;
  inherit (inputs) home-manager;
  cfg = config.${namespace}.programs.containerization.podman;

  podmanSymLinkSocketPath = "${config.home.homeDirectory}/.local/share/containers/podman/machine/podman.sock";

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
  settingsHash = builtins.hashString "sha256" (builtins.toJSON cfg.machine.settings);
in
{
  options.${namespace}.programs.containerization.podman = {
    enable = mkEnableOption "podman";
    rosetta = mkBoolOpt false "Whether or not to use rosetta.";
    autoStart = mkBoolOpt false "Whether or not to start podman machine on boot.";
    provider = mkOpt (types.enum [
      "qemu"
      "applehv"
      "libkrun"
    ]) "" "Provider to use.";
    machine = mkOpt (types.submodule {
      options = {
        enable = mkEnableOption "podman-machine";
        name = mkOpt types.str "podman-machine-default" "The name of the podman machine.";
        settings = mkOpt (types.submodule {
          options = {
            cpus = mkOpt' types.int "Number of CPUs to allocate to the VM.";
            diskSize = mkOpt' types.int "Disk size (in GB) to allocate to the VM.";
            memory = mkOpt' types.int "Memory (in MB) to allocate to the VM.";
            volume = mkOpt (types.listOf types.str) [ ] "Bind mount volumes into the VM.";
            imagePath = mkOpt types.str "" "Path to the OS image to use.";
            ignitionPath = mkOpt types.str "" "Path to a custom Ignition file.";
            now = mkBoolOpt cfg.autoStart "Start the VM immediately after init.";
            timezone = mkOpt types.str "" "Set the VM timezone.";
            rootful = mkBoolOpt false "Enable rootful mode.";
            username = mkOpt types.str "" "Username inside the VM (default core).";
            userModeNetworking = mkBoolOpt true "Enable user-mode networking (default true).";
          };
        }) { } "Podman machine settings";
      };
    }) { } "Podman machine";
    currentSocket = lib.mkOption {
      type = types.str;
      readOnly = true;
      description = "Path to the current podman machine socket";
      default = podmanSymLinkSocketPath;
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [ podman ];

      file = {
        ".config/containers/containers.conf".text = ''
          [machine]
            rosetta=${lib.boolToString cfg.rosetta}
            ${lib.optionalString (cfg.provider != "") ''provider="${cfg.provider}"''}
        '';
      };

      activation.podman-init = mkIf cfg.machine.enable (
        home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          PATH=${pkgs.openssh}/bin:${pkgs.podman}/bin:$PATH
          STATE_DIR="${config.home.homeDirectory}/.local/state/podman"
          mkdir -p "$STATE_DIR"
          HASH_FILE="$STATE_DIR/${cfg.machine.name}.hash"

          CURRENT_HASH="${settingsHash}"

          if [ ! -f "$HASH_FILE" ]; then
            echo "No previous podman machine state found, initializing..."
            ${pkgs.podman}/bin/podman machine init ${mkInitFlags cfg.machine.settings} ${cfg.machine.name}
            echo "$CURRENT_HASH" > "$HASH_FILE"
            exit 0
          fi

          if ! ${pkgs.podman}/bin/podman machine ls --format "{{.Name}}" | grep -q "^podman-machine-default\*\?$"; then
            echo "Podman machine ${cfg.machine.name} does not exist, re-initializing..."
            ${pkgs.podman}/bin/podman machine init ${mkInitFlags cfg.machine.settings} ${cfg.machine.name}
            echo "$CURRENT_HASH" > "$HASH_FILE"
            exit 0
          fi

          OLD_HASH=$(cat "$HASH_FILE")
          if [ "$OLD_HASH" != "$CURRENT_HASH" ]; then
            echo "Podman machine settings changed. Re-initializing ${cfg.machine.name}..."
            ${pkgs.podman}/bin/podman machine rm -f ${cfg.machine.name} || true
            ${pkgs.podman}/bin/podman machine init ${mkInitFlags cfg.machine.settings} ${cfg.machine.name}
            echo "$CURRENT_HASH" > "$HASH_FILE"
            exit 0
          fi

          echo "Podman machine ${cfg.machine.name} is up-to-date."

          # Always update the symlink to ensure it's current
          echo "Updating podman socket symlink..."
          ACTUAL_SOCKET_PATH=$(${pkgs.podman}/bin/podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' ${cfg.machine.name} 2>/dev/null || echo "")
          if [ -n "$ACTUAL_SOCKET_PATH" ] && [ -S "$ACTUAL_SOCKET_PATH" ]; then
            mkdir -p "$(dirname "${podmanSymLinkSocketPath}")"
            rm -f "${podmanSymLinkSocketPath}"
            ln -fs "$ACTUAL_SOCKET_PATH" "${podmanSymLinkSocketPath}"
            echo "Symlink updated: ${podmanSymLinkSocketPath} -> $ACTUAL_SOCKET_PATH"
          else
            echo "Warning: Could not find valid socket path for ${cfg.machine.name}"
          fi
        ''
      );
    };

    launchd.agents =
      let
        podmanLaunchName = "podman-launch";
        podmanLinkName = "podman-link";
      in
      {
        # TODO: This does not work, the machine started at boot is not accessible.
        ${podmanLaunchName} = mkIf (cfg.autoStart && false) {
          enable = true;
          config = {
            ProgramArguments = [
              "${pkgs.podman}/bin/podman"
              "machine"
              "start"
              "${cfg.machine.name}"
            ];
            EnvironmentVariables = {
              HOME = config.home.homeDirectory;
            };
            KeepAlive = true;
            RunAtLoad = true;
            StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/podman/${podmanLaunchName}.err.log";
            StandardOutPath = "${config.home.homeDirectory}/Library/Logs/podman/${podmanLaunchName}.out.log";
          };
        };

        ${podmanLinkName} = {
          enable = true;
          config = {
            ProgramArguments = [
              "${
                pkgs.writeShellApplication {
                  name = "${podmanLinkName}";
                  runtimeInputs = [ pkgs.podman ];
                  text = ''
                    #!/bin/sh
                    echo "Starting podman socket symlink service..."

                    # Function to update symlink
                    update_symlink() {
                      PODMAN_SOCKET_PATH=$(${pkgs.podman}/bin/podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' ${cfg.machine.name} 2>/dev/null || echo "")
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

                    # Initial update
                    update_symlink

                    # Keep monitoring and updating (runs every 30 seconds)
                    while true; do
                      sleep 30
                      update_symlink || echo "Failed to update symlink, will retry..."
                    done
                  '';
                }
              }/bin/${podmanLinkName}"
            ];
            RunAtLoad = true;
            KeepAlive = true; # Changed to true to keep it running
            StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/podman/${podmanLinkName}.err.log";
            StandardOutPath = "${config.home.homeDirectory}/Library/Logs/podman/${podmanLinkName}.out.log";
          };
        };
      };
  };
}
