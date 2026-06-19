{ lib, config, ... }:
{
  flake.modules.homeManager.homelab =
    hmArgs@{ pkgs, ... }:
    let
      cfg = hmArgs.config.services.alerting;
      alertmanagerNtfyHostPort = config.flake.meta.alerting.alertmanagerNtfy.hostPort;
      alertmanagerNtfyContainerPort = config.flake.meta.alerting.alertmanagerNtfy.containerPort;

      alertmanagerNtfyConfig = pkgs.writeText "config.yml" (
        builtins.toJSON {
          http = {
            addr = ":${toString alertmanagerNtfyContainerPort}";
          };

          ntfy = {
            baseurl = "https://ntfy.sh";
            notification = {
              topic = cfg.ntfyTopic;
              priority = ''
                alertname == "ContainerDown" ? "urgent" : "high"
              '';
              tags = [
                {
                  tag = "rotating_light";
                  condition = ''status == "firing"'';
                }
                {
                  tag = "white_check_mark";
                  condition = ''status == "resolved"'';
                }
              ];
              templates = {
                title = ''
                  {{ if eq .Status "resolved" }}Resolved: {{ end }}{{ .GroupLabels.alertname }}
                '';
                description = ''
                  {{ range .Alerts }}
                  Alert: {{ .Labels.alertname }}
                  Severity: {{ .Labels.severity }}
                  Instance: {{ .Labels.instance }}
                  {{ if .Annotations.summary }}Summary: {{ .Annotations.summary }}{{ end }}
                  {{ if .Annotations.description }}{{ .Annotations.description }}{{ end }}
                  {{ end }}
                '';
              };
            };
          };
        }
      );

      # Entrypoint script that generates auth.yml from environment variable
      entrypointScript = pkgs.writeShellScript "alertmanager-ntfy-entrypoint" ''
        #!/bin/sh
        set -e

        # Generate auth.yml with token from environment variable
        cat > /etc/auth.yml << EOF
        ntfy:
          auth:
            token: "$NTFY_TOKEN"
        EOF

        # Execute alertmanager-ntfy with both configs
        exec /usr/local/bin/alertmanager-ntfy --configs /etc/config.yml,/etc/auth.yml
      '';
    in
    lib.mkIf cfg.enable {
      services.podman.containers.alertmanager-ntfy = {
        image = "ghcr.io/alexbakker/alertmanager-ntfy:latest";
        autoStart = true;
        userNS = "keep-id";
        monitoring.enable = true;
        network = [ "alerting.network" ];
        networkAlias = [ "alertmanager-ntfy" ];
        ports = [ "${toString alertmanagerNtfyHostPort}:${toString alertmanagerNtfyContainerPort}" ];

        volumes = [
          "${alertmanagerNtfyConfig}:/etc/config.yml:ro"
          "${entrypointScript}:/entrypoint.sh:ro"
        ];

        secrets = {
          NTFY_TOKEN = cfg.ntfyTokenFile;
        };

        extraConfig.Container = {
          Entrypoint = [ "/entrypoint.sh" ];
          NoNewPrivileges = true;
        };
      };
    };
}
