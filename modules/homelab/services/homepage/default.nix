{
  lib,
  config,
  ...
}:
let
  inherit (config.flake.meta) homepage;
in
{
  flake.meta.homepage = {
    user = "homepage";
    group = "homepage";
    port = 3000;
  };

  flake.modules.nixos.homelab = {
    users.users.${homepage.user} = {
      isNormalUser = true;
      group = homepage.group;
      linger = true;
    };

    users.groups.${homepage.group} = { };
  };

  flake.homelab.services.homepage.user = config.flake.meta.homepage.user;

  flake.modules.homeManager.homelab =
    {
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.services.homepage;

      # Generate YAML configuration files
      settingsFile = pkgs.writeText "settings.yaml" (builtins.toJSON cfg.settings);
      bookmarksFile = pkgs.writeText "bookmarks.yaml" (builtins.toJSON cfg.bookmarks);
      widgetsFile = pkgs.writeText "widgets.yaml" (builtins.toJSON cfg.widgets);
      dockerFile = pkgs.writeText "docker.yaml" (builtins.toJSON cfg.docker);
    in
    {
      modules = [
        {
          options.services.homepage = {
            enable = lib.mkEnableOption "Homepage dashboard";

            port = lib.mkOption {
              type = lib.types.port;
              default = homepage.port;
              description = "Port to expose Homepage on";
            };

            appDir = lib.mkOption {
              type = lib.types.path;
              default = "/var/lib/containers/homepage";
              description = "Directory for Homepage persistent data";
            };

            settings = lib.mkOption {
              type = lib.types.attrs;
              default = {
                title = "Homelab";
                theme = "dark";
                color = "slate";
              };
              description = "Homepage settings configuration";
            };

            bookmarks = lib.mkOption {
              type = lib.types.listOf lib.types.attrs;
              default = [ ];
              description = "Homepage bookmarks configuration";
            };

            widgets = lib.mkOption {
              type = lib.types.listOf lib.types.attrs;
              default = [
                {
                  resources = {
                    cpu = true;
                    memory = true;
                    network = "eth0";
                  };
                }
              ];
              description = "Homepage widgets configuration";
            };

            docker = lib.mkOption {
              type = lib.types.attrs;
              default = {
                local = {
                  host = "dockerproxy";
                  port = 2375;
                };
              };
              description = "Homepage Docker integration configuration";
            };
          };
        }
      ];

      config = lib.mkIf cfg.enable {
        services.podman.networks.homepage.driver = "bridge";

        services.podman.containers.homepage = {
          image = "ghcr.io/gethomepage/homepage:latest";
          autoStart = true;
          userNS = "keep-id";
          network = [ "homepage.network" ];
          networkAlias = [ "homepage" ];
          ports = [ "${toString cfg.port}:3000" ];

          monitoring.enable = true;

          volumes = [
            "${cfg.appDir}/config:/app/config"
            "${settingsFile}:/app/config/settings.yaml:ro"
            "${bookmarksFile}:/app/config/bookmarks.yaml:ro"
            "${widgetsFile}:/app/config/widgets.yaml:ro"
            "${dockerFile}:/app/config/docker.yaml:ro"
          ];

          environment = {
            HOMEPAGE_ALLOWED_HOSTS = "localhost,homepage";
          };

          extraConfig.Container.NoNewPrivileges = true;
        };
      };
    };
}
