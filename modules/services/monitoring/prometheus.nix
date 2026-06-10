{ lib, config, ... }:
{
  flake.modules.homeManager."${config.flake.meta.monitoring.user}@homelab" =
    hmArgs@{ pkgs, ... }:
    let
      cfg = hmArgs.config.services.monitoring;
      prometheusPort = config.flake.meta.monitoring.prometheus.port;
      podmanExporterPort = 9882;
      retentionDays = 30;
      prometheusDir = "${cfg.storageDir}/prometheus";
      targetsDir = "${prometheusDir}/targets";

      prometheusConfig = pkgs.writeText "prometheus.yml" (
        builtins.toJSON {
          global = {
            scrape_interval = "15s";
            evaluation_interval = "15s";
          };

          scrape_configs = [
            {
              job_name = "prometheus";
              static_configs = [ { targets = [ "localhost:${toString prometheusPort}" ]; } ];
            }
            {
              job_name = "podman";
              static_configs = [ { targets = [ "podman-exporter:${toString podmanExporterPort}" ]; } ];
            }
          ];
        }
      );
    in
    lib.mkIf cfg.enable {
      services.podman.networks.monitoring.driver = "bridge";

      services.podman.containers = {
        prometheus = {
          image = "prom/prometheus:latest";
          autoStart = true;
          userNS = "keep-id";
          network = [ "monitoring.network" ];
          networkAlias = [ "prometheus" ];
          ports = [ "${toString prometheusPort}:9090" ];

          volumes = [
            "${prometheusDir}/data:/prometheus"
            "${targetsDir}:/etc/prometheus/targets:ro"
            "${prometheusConfig}:/etc/prometheus/prometheus.yml:ro"
          ];

          exec = "--config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/prometheus --storage.tsdb.retention.time=${toString retentionDays}d --web.console.libraries=/usr/share/prometheus/console_libraries --web.console.templates=/usr/share/prometheus/consoles";

          extraConfig.Container.NoNewPrivileges = true;
        };

        podman-exporter = {
          image = "quay.io/navidys/prometheus-podman-exporter:latest";
          autoStart = true;
          userNS = "keep-id";
          network = [ "monitoring.network" ];
          networkAlias = [ "podman-exporter" ];

          volumes = [
            "/run/podman/podman.sock:/var/run/podman/podman.sock:ro"
          ];

          environment = {
            CONTAINER_HOST = "unix:///var/run/podman/podman.sock";
          };

          extraConfig.Container = {
            SecurityLabelDisable = true;
            NoNewPrivileges = true;
          };
        };
      };
    };
}
