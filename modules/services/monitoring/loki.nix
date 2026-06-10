{ lib, config, ... }:
{
  flake.modules.homeManager."${config.flake.meta.monitoring.user}@homelab" =
    hmArgs@{ pkgs, ... }:
    let
      cfg = hmArgs.config.services.monitoring;
      lokiPort = config.flake.meta.monitoring.loki.port;
      retentionDays = 30;
      lokiDir = "${cfg.storageDir}/loki";

      lokiConfig = pkgs.writeText "loki.yml" (
        builtins.toJSON {
          auth_enabled = false;

          server = {
            http_listen_port = lokiPort;
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
        networkAlias = [ "loki" ];
        ports = [ "${toString lokiPort}:3100" ];

        volumes = [
          "${lokiDir}:/loki"
          "${lokiConfig}:/etc/loki/local-config.yml:ro"
        ];

        extraConfig.Container.NoNewPrivileges = true;
      };
    };
}
