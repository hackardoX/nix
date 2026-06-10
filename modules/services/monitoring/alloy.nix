{ lib, config, ... }:
{
  flake.modules.homeManager."${config.flake.meta.monitoring.user}@homelab" =
    hmArgs@{ pkgs, ... }:
    let
      cfg = hmArgs.config.services.monitoring;
      alloyPort = config.flake.meta.monitoring.alloy.port;
      alloyDir = "${cfg.storageDir}/alloy";

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
            url = "http://loki:3100/loki/api/v1/push"
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
        networkAlias = [ "alloy" ];
        ports = [ "${toString alloyPort}:12345" ];

        volumes = [
          "${alloyDir}/data:/var/lib/alloy"
          "${alloyConfig}:/etc/alloy/config.river:ro"
          "/var/log/journal:/var/log/journal:ro"
          "/etc/machine-id:/etc/machine-id:ro"
        ];

        exec = "run --server.http.listen-addr=0.0.0.0:12345 --storage.path=/var/lib/alloy/data /etc/alloy/config.river";

        extraConfig.Container.NoNewPrivileges = true;
      };
    };
}
