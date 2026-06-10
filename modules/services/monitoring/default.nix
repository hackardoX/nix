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
    };
  };

  flake.modules.homeManager."${config.flake.meta.monitoring.user}@homelab" = {
    options.services.monitoring = {
      enable = lib.mkEnableOption "Monitoring stack (Prometheus, Grafana, Loki, Alloy)";

      storageDir = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/monitoring";
        description = "Base directory for monitoring data";
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
