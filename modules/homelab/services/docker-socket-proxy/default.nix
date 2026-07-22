{
  config,
  ...
}:
let
  dockerProxyUser = "dockerproxy";
  dockerProxyGroup = "dockerproxy";
  dockerProxyImage = "ghcr.io/tecnativa/docker-socket-proxy:latest";
  # Must share the homepage network so the homepage container can reach it
  dockerProxyNetwork = "homepage";
in
{
  flake.modules.nixos.homelab-docker-socket-proxy = {
    users.users.${dockerProxyUser} = {
      isSystemUser = true;
      group = dockerProxyGroup;
      extraGroups = [
        "podman"
        "homelab-users"
      ];
      createHome = true;
      home = "/var/lib/${dockerProxyUser}";
      autoSubUidGidRange = true;
      linger = true;
    };

    users.groups.${dockerProxyGroup} = { };

    home-manager.users.${dockerProxyUser} = {
      home.username = dockerProxyUser;
      home.stateVersion = "24.11";
      imports = with config.flake.modules.homeManager; [ homelab-docker-socket-proxy ];
    };
  };

  flake.modules.homeManager.homelab-docker-socket-proxy = { osConfig, ... }: {
    config = {
      services.podman.enable = true;
      services.podman.networks.${dockerProxyNetwork}.driver = "bridge";

      services.podman.containers.dockerproxy = {
        image = dockerProxyImage;
        autoStart = true;
        userNS = "keep-id";
        network = [ "${dockerProxyNetwork}.network" ];
        networkAlias = [ "dockerproxy" ];
        environment = {
          TZ = osConfig.time.timeZone;
          CONTAINERS = "1";
          POST = "0";
          SOCKET_PATH = "/run/podman/podman.sock";
        };
        volumes = [
          "/run/podman/podman.sock:/run/podman/podman.sock:ro"
        ];
        extraConfig.Container.NoNewPrivileges = true;
      };
    };
  };
}
