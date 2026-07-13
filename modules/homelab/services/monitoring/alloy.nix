{ lib, config, ... }:
{
  flake.modules.homeManager.homelab =
    hmArgs@{ pkgs, ... }:
    let
      cfg = hmArgs.config.services.monitoring;
      alloyHost = config.flake.meta.monitoring.alloy.host;
      alloyContainerPort = config.flake.meta.monitoring.alloy.containerPort;
      alloyHostPort = config.flake.meta.monitoring.alloy.hostPort;
      lokiHost = config.flake.meta.monitoring.loki.host;
      lokiPort = config.flake.meta.monitoring.loki.containerPort;

      alloyDir = "${cfg.appDir}/alloy";

      alloyConfig = pkgs.writeText "alloy.river" ''
        logging {
          level  = "info"
          format = "logfmt"
        }

        // Relabel rules to filter and enrich container logs
        loki.relabel "containers" {
          forward_to = []

          // Keep only podman container services
          rule {
            source_labels = ["__journal__systemd_unit"]
            regex         = "podman-(.+)\\.service"
            action        = "keep"
          }

          // Extract container name from systemd unit
          rule {
            source_labels = ["__journal__systemd_unit"]
            regex         = "podman-(.+)\\.service"
            target_label  = "container"
          }

          // Add hostname
          rule {
            source_labels = ["__journal__hostname"]
            target_label  = "hostname"
          }
        }

        // Read from systemd journal
        loki.source.journal "logs" {
          forward_to    = [loki.write.default.receiver]
          relabel_rules = loki.relabel.containers.rules
          path          = "/var/log/journal"
        }

        // Write to Loki
        loki.write "default" {
          endpoint {
            url = "http://${lokiHost}:${toString lokiPort}/loki/api/v1/push"
          }
        }
      '';
    in
    lib.mkIf cfg.enable {
      services.podman.containers.alloy = {
        image = "grafana/alloy:latest";
        autoStart = true;
        userNS = "keep-id";
        network = [ "monitoring.network" ];
        networkAlias = [ alloyHost ];
        ports = [ "${toString alloyHostPort}:${toString alloyContainerPort}" ];

        volumes = [
          "${alloyDir}/data:/var/lib/alloy"
          "${alloyConfig}:/etc/alloy/config.river:ro"
          "/var/log/journal:/var/log/journal:ro"
          "/etc/machine-id:/etc/machine-id:ro"
        ];

        exec = "run --server.http.listen-addr=0.0.0.0:${toString alloyContainerPort} --storage.path=/var/lib/alloy/data /etc/alloy/config.river";

        extraConfig.Container.NoNewPrivileges = true;
      };
    };
}
