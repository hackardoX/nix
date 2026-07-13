{ lib, config, ... }:
{
  flake.modules.homeManager.homelab =
    hmArgs@{ pkgs, ... }:
    let
      cfg = hmArgs.config.services.monitoring;
      lokiHost = config.flake.meta.monitoring.loki.host;
      lokiHostPort = config.flake.meta.monitoring.loki.hostPort;
      lokiContainerPort = config.flake.meta.monitoring.loki.containerPort;
      retentionDays = 30;
      lokiDir = "${cfg.appDir}/loki";

      lokiConfig = pkgs.writeText "loki.yml" (
        builtins.toJSON {
          auth_enabled = false;

          server = {
            http_listen_port = lokiContainerPort;
          };

          common = {
            path_prefix = lokiDir;
            replication_factor = 1;
            storage = {
              filesystem = {
                chunks_directory = "${lokiDir}/chunks";
                rules_directory = "${lokiDir}/rules";
              };
            };
          };

          limits_config = {
            retention_period = "${toString retentionDays}d";
          };

          schema_config = {
            configs = [
              {
                from = "2026-06-01";
                store = "tsdb";
                object_store = "filesystem";
                schema = "v13";
                index = {
                  prefix = "index_";
                  period = "24h";
                };
              }
            ];
          };
        }
      );
    in
    lib.mkIf cfg.enable {
      services.podman.containers.loki = {
        image = "grafana/loki:latest";
        autoStart = true;
        userNS = "keep-id";
        network = [ "monitoring.network" ];
        networkAlias = [ lokiHost ];
        ports = [ "${toString lokiHostPort}:${toString lokiContainerPort}" ];

        volumes = [
          "${lokiDir}:/loki"
          "${lokiConfig}:/etc/loki/local-config.yml:ro"
        ];

        labels = config.flake.lib.mkHomepageLabels {
          category = "Monitoring";
          name = "Loki";
          description = "Log Aggregation";
          icon = "grafana.png";
          href = "http://localhost:${toString lokiHostPort}";
        };

        extraConfig.Container.NoNewPrivileges = true;
      };
    };
}
