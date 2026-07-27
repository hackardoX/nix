{
  config,
  lib,
  ...
}:
let
  homepageUser = "homepage";
  homepageGroup = "homepage";
  homepagePort = 3000;
  homepageAppDir = "/var/lib/containers/homepage";

  domain = config.flake.meta.reverse-proxy.domain;
  hosts = config.flake.meta.reverse-proxy.hosts;
  reverseProxyPort = config.flake.meta.reverse-proxy.ports.homepage;

  homepageSettings = {
    title = "Homelab";
    description = "Self-hosted services dashboard";
    theme = "dark";
    color = "slate";
    statusStyle = "dot";
    useEqualHeights = true;
    showStats = true;
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
        network = "tap0";
        label = "Network";
      };
    }
  ];
  homepageBookmarks = [ ];
  homepageDocker = {
    reactive-resume = {
      host = "127.0.0.1";
      port = config.flake.meta.reverse-proxy.ports.reactive-resume-docker-socket-proxy;
    };
    job-ops = {
      host = "127.0.0.1";
      port = config.flake.meta.reverse-proxy.ports.job-ops-docker-socket-proxy;
    };
  };
  homepagePingPorts = [
    config.flake.meta.reverse-proxy.ports.job-ops
    config.flake.meta.reverse-proxy.ports.reactive-resume
  ];
  homepageServices = [ ];
  pastaArgs = lib.concatStringsSep "," (
    [ "-t,${toString reverseProxyPort}:${toString homepagePort}" ]
    ++ (map (proxy: "-T,${toString proxy.port}") (lib.attrValues homepageDocker))
    ++ (map (port: "-T,${toString port}") homepagePingPorts)
  );
in
{
  flake.modules.nixos.homelab-homepage = { pkgs, ... }: {
    users.users.${homepageUser} = {
      isSystemUser = true;
      group = homepageGroup;
      shell = pkgs.bash;
      extraGroups = [
        "podman"
        "homelab-users"
      ];
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
        homelab-docker-socket-proxy
        homelab-homepage
        homelab-podman-extension
      ];
      services.homelab-docker-socket-proxy = {
        enable = true;
        port = config.flake.meta.reverse-proxy.ports.homepage-docker-socket-proxy;
      };
    };

    systemd.tmpfiles.rules = [
      "d ${homepageAppDir} 0750 ${homepageUser} ${homepageGroup} -"
      "d ${homepageAppDir}/config 0750 ${homepageUser} ${homepageGroup} -"
    ];

    services.caddy.virtualHosts."${domain}" = {
      extraConfig = ''
        import reverse_proxy_common
        redir https://${hosts.homepage}{uri}
      '';
    };

    services.caddy.virtualHosts."${hosts.homepage}" = {
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

      services.podman.containers.homepage = {
        image = "ghcr.io/gethomepage/homepage:latest";
        autoStart = true;
        userNS = "keep-id";
        user = "%U";
        group = "%G";
        network = [ "pasta:${pastaArgs}" ];

        monitoring.enable = true;

        volumes = [
          "${homepageAppDir}/config:/app/config"
          "${pkgs.writeText "settings.yaml" (builtins.toJSON homepageSettings)}:/app/config/settings.yaml:ro"
          "${pkgs.writeText "bookmarks.yaml" (builtins.toJSON homepageBookmarks)}:/app/config/bookmarks.yaml:ro"
          "${pkgs.writeText "widgets.yaml" (builtins.toJSON homepageWidgets)}:/app/config/widgets.yaml:ro"
          "${pkgs.writeText "services.yaml" (builtins.toJSON homepageServices)}:/app/config/services.yaml:ro"
          "${pkgs.writeText "docker.yaml" (builtins.toJSON homepageDocker)}:/app/config/docker.yaml:ro"
        ];

        environment = {
          TZ = osConfig.time.timeZone;
          HOMEPAGE_ALLOWED_HOSTS = "localhost,${hosts.homepage}";
        };

        extraConfig.Container.NoNewPrivileges = true;
      };
    };
  };
}
