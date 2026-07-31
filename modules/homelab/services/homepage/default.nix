{
  config,
  lib,
  ...
}:
let
  homepageUid = 901;
  homepageGid = 901;
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
        network = "end0";
        label = "Network";
      };
    }
  ];
  homepageBookmarks = [ ];

  allServices = config.flake.homepage.services;
  categories = lib.unique (lib.mapAttrsToList (_: s: s.category) allServices);

  servicesInCategory =
    cat:
    lib.mapAttrsToList (_: svc: {
      ${svc.name} = lib.filterAttrs (k: v: v != null) {
        inherit (svc)
          href
          description
          icon
          ping
          siteMonitor
          showStats
          statusStyle
          ;
        widget = svc.widget;
        server = svc.dockerServer;
        container = svc.container;
      };
    }) (lib.filterAttrs (_: s: s.category == cat) allServices);

  homepageServices = map (cat: { ${cat} = servicesInCategory cat; }) categories;

  homepageDocker = lib.mapAttrs (_: svc: {
    host = "127.0.0.1";
    port = svc.dockerSocketProxyPort;
  }) (lib.filterAttrs (_: s: s.dockerSocketProxyPort != null) allServices);

  homepagePingPorts = lib.attrValues (
    lib.mapAttrs (_: s: s.pingPort) (lib.filterAttrs (_: s: s.pingPort != null) allServices)
  );

  pastaArgs = lib.concatStringsSep "," (
    [ "-t,${toString reverseProxyPort}:${toString homepagePort}" ]
    ++ (map (proxy: "-T,${toString proxy.port}") (lib.attrValues homepageDocker))
    ++ (map (port: "-T,${toString port}") homepagePingPorts)
  );
in
{
  flake.modules.nixos.homelab-homepage =
    { pkgs, ... }:
    let
      homepageServicesTemplate = pkgs.writeText "services-template.json" (
        builtins.toJSON homepageServices
      );
    in
    {
      users.users.${homepageUser} = {
        uid = homepageUid;
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

      users.groups.${homepageGroup} = {
        gid = homepageGid;
      };

      home-manager.users.${homepageUser} = {
        home.username = homepageUser;
        home.stateVersion = "26.05";
        imports = with config.flake.modules.homeManager; [
          homelab-homepage
          homelab-podman-extension
          homelab-beszel-agent
        ];
        services.homelab-beszel-agent = {
          enable = true;
          port = config.flake.meta.reverse-proxy.ports.beszel-agent-homepage;
        };
      };

      systemd.tmpfiles.rules = [
        "d ${homepageAppDir} 0750 ${homepageUser} ${homepageGroup} -"
        "d ${homepageAppDir}/config 0750 ${homepageUser} ${homepageGroup} -"
      ];

      systemd.services.homepage-generate-config = {
        description = "Generate Homepage services.yaml with runtime secrets";
        before = [ "user@${toString homepageUid}.service" ];
        requiredBy = [ "user@${toString homepageUid}.service" ];
        after = [ "opnix-secrets.service" ];
        wants = [ "opnix-secrets.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          set -e
          mkdir -p ${homepageAppDir}/config

          BESZEL_USER="$(cat /run/secrets/beszel/email 2>/dev/null || true)"
          BESZEL_PASS="$(cat /run/secrets/beszel/password 2>/dev/null || true)"

          ${pkgs.jq}/bin/jq \
            --arg beszel_user "$BESZEL_USER" \
            --arg beszel_pass "$BESZEL_PASS" \
            'walk(
              if type == "object" and .widget != null and .widget.type == "beszel" then
                .widget.username = $beszel_user |
                .widget.password = $beszel_pass
              else .
              end
            )' \
            ${homepageServicesTemplate} \
            > ${homepageAppDir}/config/services.yaml

          chown ${homepageUser}:${homepageGroup} ${homepageAppDir}/config/services.yaml
          chmod 640 ${homepageAppDir}/config/services.yaml
        '';
      };

      systemd.services."home-manager-${homepageUser}" = {
        after = [
          "user@${toString homepageUid}.service"
          "opnix-secrets.service"
          "homepage-generate-config.service"
        ];
        wants = [
          "user@${toString homepageUid}.service"
          "opnix-secrets.service"
          "homepage-generate-config.service"
        ];
      };

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
        image = "ghcr.io/gethomepage/homepage:v1.13.2";
        autoStart = true;
        userNS = "keep-id:uid=0,gid=0";
        network = [ "pasta:${pastaArgs}" ];

        monitoring.enable = true;

        volumes = [
          "${homepageAppDir}/config:/app/config"
          "${pkgs.writeText "settings.yaml" (builtins.toJSON homepageSettings)}:/app/config/settings.yaml:ro"
          "${pkgs.writeText "bookmarks.yaml" (builtins.toJSON homepageBookmarks)}:/app/config/bookmarks.yaml:ro"
          "${pkgs.writeText "widgets.yaml" (builtins.toJSON homepageWidgets)}:/app/config/widgets.yaml:ro"
          "${pkgs.writeText "docker.yaml" (builtins.toJSON homepageDocker)}:/app/config/docker.yaml:ro"
          "/sys:/sys:ro"
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
