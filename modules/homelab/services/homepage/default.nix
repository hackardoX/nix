{
  config,
  ...
}:
let
  homepageUser = "homepage";
  homepageGroup = "homepage";
  homepagePort = 3000;
  homepageAppDir = "/var/lib/containers/homepage";

  domain = config.flake.meta.reverse-proxy.domain;
  reverseProxyPort = config.flake.meta.reverse-proxy.ports.homepage;

  homepageSettings = {
    title = "Homelab";
    description = "Self-hosted services dashboard";
    theme = "dark";
    color = "slate";
    statusStyle = "dot";
    useEqualHeights = true;
  };
  homepageWidgets = [
    {
      resources = {
        cpu = true;
        memory = true;
        label = "System";
      };
    }
    {
      resources = {
        disk = "/";
        label = "Storage";
      };
    }
    {
      resources = {
        network = "eth0";
        label = "Network";
      };
    }
  ];
  homepageBookmarks = [ ];
  homepageDocker = {
    local = {
      host = "dockerproxy";
      port = 2375;
    };
  };
in
{
  flake.modules.nixos.homelab-homepage = { pkgs, ... }: {
    users.users.${homepageUser} = {
      isSystemUser = true;
      group = homepageGroup;
      shell = pkgs.bash;
      extraGroups = [ "podman" ];
      createHome = true;
      home = "/var/lib/${homepageUser}";
      autoSubUidGidRange = true;
      linger = true;
    };

    users.groups.${homepageGroup} = { };

    home-manager.users.${homepageUser} = {
      home.username = homepageUser;
      home.stateVersion = "26.05";
      imports = with config.flake.modules.homeManager; [
        homelab-homepage
        homelab-podman-extension
      ];
    };

    services.caddy.virtualHosts."${domain}" = {
      extraConfig = ''
        import reverse_proxy_common
        redir https://homepage.${domain}{uri}
      '';
    };

    services.caddy.virtualHosts."homepage.${domain}" = {
      extraConfig = ''
        import auth_protected
        import reverse_proxy_common
        reverse_proxy localhost:${toString reverseProxyPort}
      '';
    };
  };

  flake.modules.homeManager.homelab-homepage = { osConfig, pkgs, ... }: {
    config = {
      services.podman.enable = true;
      services.podman.networks.homepage.driver = "bridge";

      services.podman.containers.homepage = {
        image = "ghcr.io/gethomepage/homepage:latest";
        autoStart = true;
        userNS = "keep-id";
        network = [ "homepage.network" ];
        networkAlias = [ "homepage" ];
        ports = [ "${toString reverseProxyPort}:${toString homepagePort}" ];

        monitoring.enable = true;

        volumes = [
          "${homepageAppDir}/config:/app/config"
          "${pkgs.writeText "settings.yaml" (builtins.toJSON homepageSettings)}:/app/config/settings.yaml:ro"
          "${pkgs.writeText "bookmarks.yaml" (builtins.toJSON homepageBookmarks)}:/app/config/bookmarks.yaml:ro"
          "${pkgs.writeText "widgets.yaml" (builtins.toJSON homepageWidgets)}:/app/config/widgets.yaml:ro"
          "${pkgs.writeText "docker.yaml" (builtins.toJSON homepageDocker)}:/app/config/docker.yaml:ro"
        ];

        environment = {
          TZ = osConfig.time.timeZone;
          HOMEPAGE_ALLOWED_HOSTS = "localhost,homepage";
        };

        extraConfig.Container.NoNewPrivileges = true;
      };
    };
  };
}
