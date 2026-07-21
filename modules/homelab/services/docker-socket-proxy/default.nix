{ config, lib, ... }:
let
  inherit (lib) types;
in
{
  flake.meta.docker-socket-proxy = {
    user = "dockerproxy";
    group = "dockerproxy";
  };

  flake.modules.nixos.homelab = {
    users.users.${config.flake.meta.docker-socket-proxy.user} = {
      isSystemUser = true;
      group = config.flake.meta.docker-socket-proxy.group;
      extraGroups = [ "podman" ];
      createHome = true;
      home = "/var/lib/${config.flake.meta.docker-socket-proxy.user}";
      autoSubUidGidRange = true;
      linger = true;
    };

    users.groups.${config.flake.meta.docker-socket-proxy.group} = { };
  };

  flake.homelab.services.docker-socket-proxy.user = config.flake.meta.docker-socket-proxy.user;

  flake.modules.homeManager.homelab = hmArgs: {
    options.services.docker-socket-proxy = {
      enable = lib.mkEnableOption "Docker socket proxy for Homepage";

      image = lib.mkOption {
        type = types.str;
        default = "ghcr.io/tecnativa/docker-socket-proxy:latest";
        description = "Docker socket proxy container image";
      };

      network = lib.mkOption {
        type = types.str;
        description = "Podman network to attach to";
      };
    };

    config = lib.mkIf hmArgs.config.services.docker-socket-proxy.enable {
      services.podman.containers.dockerproxy = {
        image = hmArgs.config.services.docker-socket-proxy.image;
        autoStart = true;
        userNS = "keep-id";
        network = [ "${hmArgs.config.services.docker-socket-proxy.network}.network" ];
        networkAlias = [ "dockerproxy" ];

        environment = {
          CONTAINERS = "1";
          POST = "0";
          SOCKET_PATH = "/run/podman/podman.sock";
        };

        volumes = [
          "/run/podman/podman.sock:/run/podman/podman.sock:ro"
        ];
      };
    };
  };
}
