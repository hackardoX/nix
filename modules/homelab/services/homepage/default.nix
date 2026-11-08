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
  homepageAppDir = "/var/lib/podman/homepage";

  domain = config.flake.meta.reverse-proxy.domain;
  hosts = config.flake.meta.reverse-proxy.hosts;
  reverseProxyPort = config.flake.meta.reverse-proxy.ports.homepage;
  oidcClientId = config.flake.meta.oidc-clients.homepage.clientId;

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

  allServices = config.flake.meta.homepage.services;
  categories = lib.unique (lib.mapAttrsToList (_: s: s.category) allServices);

  servicesInCategory =
    cat:
    lib.mapAttrsToList (_: svc: {
      ${svc.name} = lib.filterAttrs (_: v: v != null) {
        inherit (svc)
          href
          description
          icon
          ping
          siteMonitor
          showStats
          statusStyle
          ;
        inherit (svc) widget;
        widgets = if svc.widgets == [ ] then null else svc.widgets;
        server = svc.dockerServer;
        inherit (svc) container;
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
  # Homepage's own sign-in gate (HOMEPAGE_AUTH_ENABLED) on top of the Caddy
  # forward-auth. Homepage lets in whoever Authelia authorizes for this client,
  # so the policy is the only access rule.
  flake.meta.oidc-clients.homepage = {
    clientId = "homepage";
    clientName = "Homepage";
    policy = "admin-only";
    redirectUris = [ "https://${hosts.homepage}/api/auth/callback/homepage-oidc" ];
    extraYamlLines = [
      ''token_endpoint_auth_method: "client_secret_basic"''
    ];
  };

  flake.modules.nixos.homelab-homepage =
    { pkgs, ... }:
    {
      users.users.${homepageUser} = {
        uid = homepageUid;
        isSystemUser = true;
        group = homepageGroup;
        shell = pkgs.bash;
        extraGroups = [
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
          podman-secrets
          homelab-homepage
          homelab-beszel-agent
          homelab-docker-socket-proxy
        ];
        services.homelab-beszel-agent = {
          enable = true;
          port = config.flake.meta.reverse-proxy.ports.beszel-agent-homepage;
        };
        services.homelab-docker-socket-proxy = {
          enable = true;
          port = config.flake.meta.reverse-proxy.ports.homepage-docker-socket-proxy;
        };
      };

      systemd.tmpfiles.rules = [
        "d ${homepageAppDir} 0750 ${homepageUser} ${homepageGroup} -"
        "d ${homepageAppDir}/config 0750 ${homepageUser} ${homepageGroup} -"
        # Older deployments generated a services.yaml holding the Beszel
        # password here. It is now mounted from the Nix store, so drop the copy.
        "r ${homepageAppDir}/config/services.yaml"
      ];

      # Homepage reads the Beszel credentials from these files (see
      # HOMEPAGE_FILE_* below), so they never land in services.yaml. They reuse
      # the Beszel hub's sops entries but are owned by the homepage user.
      sops.secrets = {
        "homepage/beszel_user" = {
          key = "beszel/email";
          owner = homepageUser;
          group = homepageGroup;
        };
        "homepage/beszel_password" = {
          key = "beszel/password";
          owner = homepageUser;
          group = homepageGroup;
        };
        # API keys for the Immich and Tandoor widgets. Both are created in the
        # app (see the widget notes in each service module), then stored here.
        "homepage/immich_key" = {
          owner = homepageUser;
          group = homepageGroup;
        };
        "homepage/tandoor_key" = {
          owner = homepageUser;
          group = homepageGroup;
        };
        # Signs and encrypts the session cookie.
        "homepage/auth_secret" = {
          owner = homepageUser;
          group = homepageGroup;
        };
        # Same value as authelia_oidc/homepage, which Authelia stores hashed.
        "homepage/oidc_client_secret" = {
          owner = homepageUser;
          group = homepageGroup;
        };
        "authelia_oidc/homepage" = {
          owner = config.flake.meta.users.authelia.name;
          group = config.flake.meta.users.authelia.primaryGroup;
          restartUnits = [ "authelia-default.service" ];
        };
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
        image = "ghcr.io/gethomepage/homepage:v2.7.0@sha256:19c5c09184458a41b7b5915e71463a39f36cd33540f41bdbed008791b8182d5f";
        autoStart = true;
        userNS = "keep-id:uid=0,gid=0";
        network = [ "pasta:${pastaArgs}" ];

        volumes = [
          "${homepageAppDir}/config:/app/config"
          "${pkgs.writeText "services.yaml" (builtins.toJSON homepageServices)}:/app/config/services.yaml:ro"
          "${osConfig.sops.secrets."homepage/beszel_user".path}:/run/homepage/beszel_user:ro"
          "${osConfig.sops.secrets."homepage/beszel_password".path}:/run/homepage/beszel_password:ro"
          "${osConfig.sops.secrets."homepage/immich_key".path}:/run/homepage/immich_key:ro"
          "${osConfig.sops.secrets."homepage/tandoor_key".path}:/run/homepage/tandoor_key:ro"
          "${pkgs.writeText "settings.yaml" (builtins.toJSON homepageSettings)}:/app/config/settings.yaml:ro"
          "${pkgs.writeText "bookmarks.yaml" (builtins.toJSON homepageBookmarks)}:/app/config/bookmarks.yaml:ro"
          "${pkgs.writeText "widgets.yaml" (builtins.toJSON homepageWidgets)}:/app/config/widgets.yaml:ro"
          "${pkgs.writeText "docker.yaml" (builtins.toJSON homepageDocker)}:/app/config/docker.yaml:ro"
          "/sys:/sys:ro"
        ];

        environment = {
          TZ = osConfig.time.timeZone;
          HOMEPAGE_ALLOWED_HOSTS = "localhost,${hosts.homepage}";
          HOMEPAGE_FILE_BESZEL_USER = "/run/homepage/beszel_user";
          HOMEPAGE_FILE_BESZEL_PASSWORD = "/run/homepage/beszel_password";
          HOMEPAGE_FILE_IMMICH_KEY = "/run/homepage/immich_key";
          HOMEPAGE_FILE_TANDOOR_KEY = "/run/homepage/tandoor_key";
          HOMEPAGE_AUTH_ENABLED = "true";
          HOMEPAGE_EXTERNAL_URL = "https://${hosts.homepage}";
          HOMEPAGE_OIDC_ISSUER = "https://${hosts.auth}";
          HOMEPAGE_OIDC_CLIENT_ID = oidcClientId;
          HOMEPAGE_OIDC_NAME = "Authelia";
        };

        # Homepage reads these two from the environment only (HOMEPAGE_FILE_*
        # works for config templating, not for auth).
        secrets = {
          HOMEPAGE_AUTH_SECRET = osConfig.sops.secrets."homepage/auth_secret".path;
          HOMEPAGE_OIDC_CLIENT_SECRET = osConfig.sops.secrets."homepage/oidc_client_secret".path;
        };

        extraConfig.Container.Memory = "256m";
        extraConfig.Container.NoNewPrivileges = true;
      };
    };
  };
}
