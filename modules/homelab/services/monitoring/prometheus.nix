{ lib, config, ... }:
{
  flake.modules.homeManager.homelab =
    hmArgs@{ pkgs, ... }:
    let
      cfg = hmArgs.config.services.monitoring;
      prometheusHost = config.flake.meta.monitoring.prometheus.host;
      prometheusHostPort = config.flake.meta.monitoring.prometheus.hostPort;
      prometheusContainerPort = config.flake.meta.monitoring.prometheus.containerPort;
      prometheusPodmanExporterHost = config.flake.meta.monitoring.prometheusPodmanExporter.host;
      prometheusPodmanExporterPort = config.flake.meta.monitoring.prometheusPodmanExporter.hostPort;
      retentionDays = 30;
      prometheusDir = "${cfg.appDir}/prometheus";
      targetsDir = "${prometheusDir}/targets";

      alertRulesConfig = {
        groups = lib.mapAttrsToList (name: group: {
          inherit name;
          rules = map (rule: {
            inherit (rule) alert expr;
            for = rule.for;
            labels = rule.labels;
            annotations = rule.annotations;
          }) group.rules;
        }) cfg.prometheus.alertRules;
      };

      alertRulesFile = pkgs.writeText "alert-rules.yml" (builtins.toJSON alertRulesConfig);

      prometheusConfig = pkgs.writeText "prometheus.yml" (
        builtins.toJSON {
          global = {
            scrape_interval = "15s";
            evaluation_interval = "15s";
          };

          rule_files = [ "/etc/prometheus/alert-rules.yml" ];

          scrape_configs = [
            {
              job_name = "prometheus";
              static_configs = [ { targets = [ "localhost:${toString prometheusHostPort}" ]; } ];
            }
            {
              job_name = "podman";
              static_configs = [
                { targets = [ "${prometheusPodmanExporterHost}:${toString prometheusPodmanExporterPort}" ]; }
              ];
            }
            {
              job_name = "crowdsec";
              static_configs = [
                { targets = [ "host.containers.internal:6060" ]; }
              ];
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
          networkAlias = [ prometheusHost ];
          ports = [ "${toString prometheusHostPort}:${toString prometheusContainerPort}" ];

          volumes = [
            "${prometheusDir}/data:/prometheus"
            "${targetsDir}:/etc/prometheus/targets:ro"
            "${prometheusConfig}:/etc/prometheus/prometheus.yml:ro"
            "${alertRulesFile}:/etc/prometheus/alert-rules.yml:ro"
          ];

          labels = config.flake.lib.mkHomepageLabels {
            category = "Monitoring";
            name = "Prometheus";
            description = "Metrics Storage";
            icon = "prometheus.png";
            href = "http://localhost:${toString prometheusHostPort}";
          };

          exec = "--config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/prometheus --storage.tsdb.retention.time=${toString retentionDays}d --web.console.libraries=/usr/share/prometheus/console_libraries --web.console.templates=/usr/share/prometheus/consoles";

          extraConfig.Container.NoNewPrivileges = true;
        };

        podman-exporter = {
          image = "quay.io/navidys/prometheus-podman-exporter:latest";
          autoStart = true;
          userNS = "keep-id";
          network = [ "monitoring.network" ];
          networkAlias = [ prometheusPodmanExporterHost ];

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
