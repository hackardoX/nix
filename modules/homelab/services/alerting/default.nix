{
  config,
  ...
}:
let
  alertingUser = "alerting";
  alertingGroup = "alerting";
  alertingAppDir = "/var/lib/containers/alerting";

  alertmanagerHostPort = 9093;
  alertmanagerContainerPort = 9093;
  alertmanagerNtfyHostPort = 8000;
  alertmanagerNtfyContainerPort = 8000;
  alertingNtfyTopic = "homelab-alerts";

  alertingNtfyTokenSecretPath = "/run/secrets/alerting_ntfy_token";
in
{
  flake.modules.nixos.homelab-alerting = {
    users.users.${alertingUser} = {
      isSystemUser = true;
      group = alertingGroup;
      extraGroups = [ "podman" ];
      createHome = true;
      home = "/var/lib/${alertingUser}";
      autoSubUidGidRange = true;
      linger = true;
    };

    users.groups.${alertingGroup} = { };

    home-manager.users.${alertingUser} = {
      home.username = alertingUser;
      home.stateVersion = "26.05";
      imports = with config.flake.modules.homeManager; [
        base
        homelab-alerting
        backup
        homelab-podman-extension
        podman-secrets
      ];
    };
  };

  flake.modules.homeManager.homelab-alerting =
    hmArgs@{
      osConfig,
      pkgs,
      ...
    }:
    let
      alertmanagerConfig = pkgs.writeText "alertmanager.yml" (
        builtins.toJSON {
          global.resolve_timeout = "5m";
          route = {
            group_by = [ "alertname" ];
            group_wait = "30s";
            group_interval = "5m";
            repeat_interval = "4h";
            receiver = "ntfy";
          };
          receivers = [
            {
              name = "ntfy";
              webhook_configs = [
                {
                  url = "http://alertmanager-ntfy:${toString alertmanagerNtfyContainerPort}/hook";
                  send_resolved = true;
                }
              ];
            }
          ];
        }
      );

      alertmanagerNtfyConfig = pkgs.writeText "config.yml" (
        builtins.toJSON {
          http.addr = ":${toString alertmanagerNtfyContainerPort}";
          ntfy = {
            baseurl = "https://ntfy.sh";
            notification = {
              topic = alertingNtfyTopic;
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

      entrypointScript = pkgs.writeShellScript "alertmanager-ntfy-entrypoint" ''
        set -e
        cat > /etc/auth.yml << EOF
        ntfy:
          auth:
            token: "$NTFY_TOKEN"
        EOF
        exec /usr/local/bin/alertmanager-ntfy --configs /etc/config.yml,/etc/auth.yml
      '';
    in
    {
      config = {
        programs.onepassword-secrets.secrets.alertingNtfyToken = {
          path = alertingNtfyTokenSecretPath;
          reference = "op://Homelab/Alerting/ntfy token";
          owner = alertingUser;
          group = alertingGroup;
        };
        programs.onepassword-secrets.secrets.backupAlertmanagerEncryptionKey = {
          path = "/run/secrets/alerting/backup_encryption_key";
          reference = "op://Homelab/Backup/alertmanager/password";
          owner = alertingUser;
          group = alertingGroup;
        };

        services.backup.jobs.alertmanager = {
          paths = [ "${alertingAppDir}/alertmanager/data" ];
          schedule = "weekly";
          retention = "extended";
          providers = [ "koofr" ];
          encryptionKey =
            hmArgs.config.programs.onepassword-secrets.secretPaths.backupAlertmanagerEncryptionKey;
        };

        services.podman.enable = true;
        services.podman.networks.alerting.driver = "bridge";

        services.podman.containers.alertmanager = {
          image = "prom/alertmanager:latest";
          autoStart = true;
          userNS = "keep-id";
          network = [ "alerting.network" ];
          networkAlias = [ "alertmanager" ];
          ports = [ "${toString alertmanagerHostPort}:${toString alertmanagerContainerPort}" ];
          monitoring.enable = true;

          environment.TZ = osConfig.time.timeZone;

          volumes = [
            "${alertingAppDir}/alertmanager/data:/alertmanager"
            "${alertmanagerConfig}:/etc/alertmanager/alertmanager.yml:ro"
          ];

          exec = "--config.file=/etc/alertmanager/alertmanager.yml --storage.path=/alertmanager";
          extraConfig.Container.NoNewPrivileges = true;
        };

        services.podman.containers.alertmanager-ntfy = {
          image = "ghcr.io/alexbakker/alertmanager-ntfy:latest";
          autoStart = true;
          userNS = "keep-id";
          network = [ "alerting.network" ];
          networkAlias = [ "alertmanager-ntfy" ];
          ports = [ "${toString alertmanagerNtfyHostPort}:${toString alertmanagerNtfyContainerPort}" ];
          monitoring.enable = true;

          environment.TZ = osConfig.time.timeZone;

          volumes = [
            "${alertmanagerNtfyConfig}:/etc/config.yml:ro"
            "${entrypointScript}:/entrypoint.sh:ro"
          ];

          secrets = {
            NTFY_TOKEN = hmArgs.config.programs.onepassword-secrets.secretPaths.alertingNtfyToken;
          };

          extraConfig.Container = {
            Entrypoint = [ "/entrypoint.sh" ];
            NoNewPrivileges = true;
          };
        };
      };
    };
}
