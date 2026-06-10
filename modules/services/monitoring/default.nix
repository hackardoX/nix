{ lib, config, ... }:
{
  flake.meta.monitoring = {
    user = "monitoring";
    group = "monitoring";
    prometheus.port = 9090;
    grafana.port = 3000;
    loki.port = 3100;
    alloy.port = 12345;
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

  flake.modules.homeManager."${config.flake.meta.monitoring.user}@homelab" =
    hmArgs:
    let
      cfg = hmArgs.config.services.monitoring;
    in
    {
      options.services.monitoring = {
        enable = lib.mkEnableOption "Monitoring stack (Prometheus, Grafana, Loki, Alloy)";

        storageDir = lib.mkOption {
          type = lib.types.path;
          default = "/var/lib/monitoring";
          description = "Base directory for monitoring data";
        };
      };
    };
}
