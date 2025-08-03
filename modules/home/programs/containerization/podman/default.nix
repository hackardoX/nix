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

  podmanSymLinkSocketPath = "/tmp/podman.sock";

  mkInitFlags =
    settings:
    lib.concatStringsSep " " (
      lib.flatten [
        (lib.optional (settings.cpus != null) (mkOptFlag "cpus" settings.cpus))
        (lib.optional (settings.diskSize != null) (mkOptFlag "disk-size" "${settings.diskSize}"))
        (lib.optional (settings.memory != null) (mkOptFlag "memory" "${settings.memory}"))
        (lib.optional (settings.imagePath != "") (mkOptFlag "image-path" settings.imagePath))
        (lib.optional (settings.ignitionPath != "") (mkOptFlag "ignition-path" settings.ignitionPath))
        (lib.optional settings.now "--now")
        (lib.optional settings.rootful "--rootful")
        (lib.optional (settings.timezone != "") (mkOptFlag "timezone" settings.timezone))
        (lib.optional (settings.username != "") (mkOptFlag "username" settings.username))
        (lib.optional (settings.volumeDriver != "") (mkOptFlag "volume-driver" settings.volumeDriver))
        (lib.optional (settings.provider != "") (mkOptFlag "provider" settings.provider))
        (lib.optional (settings.imageVolume != "") (mkOptFlag "image-volume" settings.imageVolume))
        (lib.optional (settings.keymap != "") (mkOptFlag "keymap" settings.keymap))
        (lib.optional (!settings.userModeNetworking) "--no-user-mode-networking")
        (lib.optional (settings.volume != [ ]) (mkOptList "volume" settings.volume))
        (lib.optional (settings.uidmap != [ ]) (mkOptList "uidmap" settings.uidmap))
        (lib.optional (settings.gidmap != [ ]) (mkOptList "gidmap" settings.gidmap))
        (lib.optional (settings.dns != [ ]) (mkOptList "dns" settings.dns))
        (lib.optional (settings.publish != [ ]) (mkOptList "publish" settings.publish))
      ]
    );
  settingsHash = builtins.hashString "sha256" (builtins.toJSON cfg.machine.settings);
in
{
  options.${namespace}.programs.containerization.podman = {
    enable = mkEnableOption "podman";
    rosetta = mkBoolOpt false "Whether or not to use rosetta.";
    aliasDocker = mkBoolOpt false "Whether or not to alias docker to podman.";
    autoStart = mkBoolOpt false "Whether or not to start podman machine on boot.";
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
            rootful = mkBoolOpt false "Enable rootful mode.";
            timezone = mkOpt types.str "" "Set the VM timezone.";
            username = mkOpt types.str "" "Username inside the VM (default core).";
            uidmap = mkOpt (types.listOf types.str) [ ] "UID mapping in the VM.";
            gidmap = mkOpt (types.listOf types.str) [ ] "GID mapping in the VM.";
            volumeDriver = mkOpt types.str "" "Driver for volume mounting (virtiofs, 9p, etc).";
            provider = mkOpt types.str "" "Provider to use (qemu or applehv).";
            imageVolume = mkOpt types.str "" "Volume name for storing the VM image.";
            userModeNetworking = mkBoolOpt true "Enable user-mode networking (default true).";
            dns = mkOpt (types.listOf types.str) [ ] "Custom DNS servers for the VM.";
            publish = mkOpt (types.listOf types.str) [ ] "Publish VM ports to the host.";
            keymap = mkOpt types.str "" "Set the VM keyboard layout.";
          };
        }) { } "Podman machine settings";
      };
    }) { } "Podman machine";
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [ podman ];

      file = {
        ".config/containers/containers.conf".text = ''
          [machine]
            rosetta=${lib.boolToString cfg.rosetta}
            provider = "${cfg.machine.settings.provider}"
        '';
      };

      shellAliases = lib.mkIf cfg.aliasDocker {
        docker = "podman";
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
                    PODMAN_SOCKET_PATH=$(${pkgs.podman}/bin/podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}')
                    if [ -z "$PODMAN_SOCKET_PATH" ]; then
                      echo "Podman socket path not found"
                      exit 1
                    fi
                    if [ ! -e "${podmanSymLinkSocketPath}" ] && ln -fs "$PODMAN_SOCKET_PATH" "${podmanSymLinkSocketPath}"; then
                      echo "Symlink created: ${podmanSymLinkSocketPath} -> $PODMAN_SOCKET_PATH"
                    fi
                  '';
                }
              }/bin/${podmanLinkName}"
            ];
            RunAtLoad = true;
            KeepAlive = false;
            StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/podman/${podmanLinkName}.err.log";
            StandardOutPath = "${config.home.homeDirectory}/Library/Logs/podman/${podmanLinkName}.out.log";
          };
        };
      };
  };
}
