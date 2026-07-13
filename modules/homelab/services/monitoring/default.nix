{ lib, config, ... }:
{
  flake.meta.monitoring = {
    user = "monitoring";
    group = "monitoring";
    prometheus = {
      containerPort = 9090;
      hostPort = 9090;
      host = "prometheus";
    };
    prometheusPodmanExporter = {
      containerPort = 9882;
      hostPort = 9882;
      host = "podman-exporter";
    };
    grafana = {
      containerPort = 3000;
      hostPort = 3000;
      host = "grafana";
    };
    loki = {
      containerPort = 3100;
      hostPort = 3100;
      host = "loki";
    };
    alloy = {
      containerPort = 12345;
      hostPort = 12345;
      host = "alloy";
    };
  };

  flake.modules.nixos.homelab = {
    users.users.${config.flake.meta.monitoring.user} = {
      isNormalUser = true;
      extraGroups = [
        config.flake.meta.monitoring.group
        "systemd-journal"
      ];
      linger = true;
    };
  };

  flake.homelab.services.monitoring.user = config.flake.meta.monitoring.user;

  flake.modules.homeManager.homelab = {
    options.services.monitoring = {
      enable = lib.mkEnableOption "Monitoring stack (Prometheus, Grafana, Loki, Alloy)";

      appDir = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/containers/monitoring";
        description = "Base directory for monitoring data";
      };

      grafana.oidcClientSecretFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to file containing Grafana OIDC client secret for Authelia";
      };

      prometheus.alertRules = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options.rules = lib.mkOption {
              type = lib.types.listOf (
                lib.types.submodule {
                  options = {
                    alert = lib.mkOption {
                      type = lib.types.str;
                      description = "Name of the alert";
                    };
                    expr = lib.mkOption {
                      type = lib.types.str;
                      description = "PromQL expression to evaluate";
                    };
                    for = lib.mkOption {
                      type = lib.types.str;
                      default = "5m";
                      description = "Duration to wait before firing the alert";
                    };
                    labels = lib.mkOption {
                      type = lib.types.attrsOf lib.types.str;
                      default = { };
                      description = "Labels to attach to the alert";
                    };
                    annotations = lib.mkOption {
                      type = lib.types.attrsOf lib.types.str;
                      default = { };
                      description = "Annotations to attach to the alert";
                    };
                  };
                }
              );
              default = [ ];
              description = "List of alert rules in this group";
            };
          }
        );
        default = { };
        description = "Prometheus alert rule groups";
      };
    };
  };
}
