{
  config,
  lib,
  ...
}:
let
  monitoringUser = "monitoring";
  monitoringGroup = "monitoring";
  monitoringAppDir = "/var/lib/containers/monitoring";

  domain = config.flake.meta.reverse-proxy.domain;
  mkHomepageLabels = config.flake.lib.mkHomepageLabels;

  prometheusHost = "prometheus";
  prometheusContainerPort = 9090;
  prometheusHostPort = 9090;

  podmanExporterHost = "podman-exporter";
  podmanExporterContainerPort = 9882;
  podmanExporterHostPort = 9882;

  grafanaHost = "grafana";
  grafanaContainerPort = 3000;
  grafanaHostPort = 3000;

  lokiHost = "loki";
  lokiContainerPort = 3100;
  lokiHostPort = 3100;

  alloyHost = "alloy";
  alloyContainerPort = 12345;
  alloyHostPort = 12345;

  oidcEnabled = true;
  grafanaOidcClientId = config.flake.meta.oidc-clients.grafana.clientId or "";
  grafanaOidcSecretFile = "/run/secrets/monitoring/grafana/oidc_client_secret";
in
{
  flake.modules.nixos.monitoring = {
    users.users.${monitoringUser} = {
      isSystemUser = true;
      group = monitoringGroup;
      extraGroups = [
        "systemd-journal"
        "podman"
      ];
      createHome = true;
      home = "/var/lib/${monitoringUser}";
      autoSubUidGidRange = true;
      linger = true;
    };

    users.groups.${monitoringGroup} = { };

    home-manager.users.${monitoringUser} = {
      imports = with config.flake.modules.homeManager; [
        base
        backup
        monitoring
        podman-extension
      ];
    };
  };

  flake.modules.homeManager.podman-extension = {
    options.services.podman.containers = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { config, ... }:
          {
            options.monitoring = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Enable Alloy log collection for this container";
              };
            };

            config = lib.mkIf config.monitoring.enable {
              extraConfig.Container.Labels."logging.alloy" = "true";
            };
          }
        )
      );
    };
  };

  flake.modules.homeManager.monitoring =
    hmArgs@{
      osConfig,
      pkgs,
      ...
    }:
    let
      prometheusConfig = pkgs.writeText "prometheus.yml" (
        builtins.toJSON {
          global = {
            scrape_interval = "15s";
            evaluation_interval = "15s";
          };
          scrape_configs = [
            {
              job_name = "prometheus";
              static_configs = [ { targets = [ "localhost:${toString prometheusHostPort}" ]; } ];
            }
            {
              job_name = "podman";
              static_configs = [
                { targets = [ "${podmanExporterHost}:${toString podmanExporterHostPort}" ]; }
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

      alertRulesConfig = {
        groups = [
          {
            name = "container_health";
            rules = [
              {
                alert = "ContainerDown";
                expr = "up == 0";
                for = "5m";
                labels.severity = "critical";
                annotations = {
                  summary = "Container {{ $labels.instance }} is down";
                  description = "Container has been unreachable for more than 5 minutes";
                };
              }
            ];
          }
          {
            name = "resource_usage";
            rules = [
              {
                alert = "HighCPUUsage";
                expr = "rate(container_cpu_usage_seconds_total[5m]) > 0.8";
                for = "5m";
                labels.severity = "critical";
                annotations = {
                  summary = "High CPU usage on {{ $labels.instance }}";
                  description = "CPU usage is above 80% for 5 minutes";
                };
              }
              {
                alert = "HighMemoryUsage";
                expr = "container_memory_usage_bytes / container_memory_limit_bytes > 0.85";
                for = "5m";
                labels.severity = "critical";
                annotations = {
                  summary = "High memory usage on {{ $labels.instance }}";
                  description = "Memory usage is above 85% for 5 minutes";
                };
              }
              {
                alert = "LowDiskSpace";
                expr = "node_filesystem_avail_bytes / node_filesystem_size_bytes < 0.15";
                for = "5m";
                labels.severity = "critical";
                annotations = {
                  summary = "Low disk space on {{ $labels.instance }}";
                  description = "Disk space is below 15% (85% used)";
                };
              }
            ];
          }
        ];
      };

      alertRulesFile = pkgs.writeText "alert-rules.yml" (builtins.toJSON alertRulesConfig);

      datasourcesConfig = pkgs.writeText "datasources.yml" (
        builtins.toJSON {
          apiVersion = 1;
          datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              url = "http://${prometheusHost}:${toString prometheusContainerPort}";
              isDefault = true;
            }
            {
              name = "Loki";
              type = "loki";
              url = "http://${lokiHost}:${toString lokiContainerPort}";
              isDefault = false;
            }
          ];
        }
      );

      lokiConfig = pkgs.writeText "loki.yml" (
        builtins.toJSON {
          auth_enabled = false;
          server.http_listen_port = lokiContainerPort;
          common = {
            path_prefix = "/loki";
            replication_factor = 1;
            storage.filesystem = {
              chunks_directory = "/loki/chunks";
              rules_directory = "/loki/rules";
            };
          };
          limits_config.retention_period = "30d";
          schema_config.configs = [
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
        }
      );

      alloyConfig = pkgs.writeText "alloy.river" ''
        logging {
          level  = "info"
          format = "logfmt"
        }

        loki.relabel "containers" {
          forward_to = []
          rule {
            source_labels = ["__journal__systemd_unit"]
            regex         = "podman-(.+)\\.service"
            action        = "keep"
          }
          rule {
            source_labels = ["__journal__systemd_unit"]
            regex         = "podman-(.+)\\.service"
            target_label  = "container"
          }
          rule {
            source_labels = ["__journal__hostname"]
            target_label  = "hostname"
          }
        }

        loki.source.journal "logs" {
          forward_to    = [loki.write.default.receiver]
          relabel_rules = loki.relabel.containers.rules
          path          = "/var/log/journal"
        }

        loki.write "default" {
          endpoint {
            url = "http://${lokiHost}:${toString lokiContainerPort}/loki/api/v1/push"
          }
        }
      '';

      grafanaOidcEnv = lib.optionalAttrs oidcEnabled {
        GF_AUTH_GENERIC_OAUTH_ENABLED = "true";
        GF_AUTH_GENERIC_OAUTH_NAME = "Authelia";
        GF_AUTH_GENERIC_OAUTH_CLIENT_ID = grafanaOidcClientId;
        GF_AUTH_GENERIC_OAUTH_SCOPES = "openid profile email";
        GF_AUTH_GENERIC_OAUTH_AUTH_URL = "https://auth.${domain}/api/oidc/authorization";
        GF_AUTH_GENERIC_OAUTH_TOKEN_URL = "https://auth.${domain}/api/oidc/token";
        GF_AUTH_GENERIC_OAUTH_API_URL = "https://auth.${domain}/api/oidc/userinfo";
        GF_AUTH_GENERIC_OAUTH_ALLOW_SIGN_UP = "true";
        GF_AUTH_GENERIC_OAUTH_AUTO_LOGIN = "true";
        GF_SERVER_ROOT_URL = "https://grafana.${domain}";
      };
    in
    {
      config = {
        programs.onepassword-secrets.secrets = {
          grafanaOidcClientSecret = {
            path = "/run/secrets/monitoring/grafana/oidc_client_secret";
            reference = "op://Homelab/Grafana/Authentication/OIDC Client Secret";
            owner = monitoringUser;
            group = monitoringGroup;
          };
          backupGrafanaEncryptionKey = {
            path = "/run/secrets/monitoring/grafana/backup_encryption_key";
            reference = "op://Homelab/Backup/grafana/password";
            owner = monitoringUser;
            group = monitoringGroup;
          };
        };

        services.backup.jobs.grafana = {
          paths = [ "${monitoringAppDir}/grafana/data" ];
          schedule = "weekly";
          retention = "extended";
          providers = [ "koofr" ];
          encryptionKey = hmArgs.config.services.onepassword-secrets.secretPaths.backupGrafanaEncryptionKey;
        };

        services.podman.enable = true;
        services.podman.networks.monitoring.driver = "bridge";

        services.podman.containers.prometheus = {
          image = "prom/prometheus:latest";
          autoStart = true;
          userNS = "keep-id";
          network = [ "monitoring.network" ];
          networkAlias = [ prometheusHost ];
          ports = [ "${toString prometheusHostPort}:${toString prometheusContainerPort}" ];

          environment.TZ = osConfig.time.timeZone;

          volumes = [
            "${monitoringAppDir}/prometheus/data:/prometheus"
            "${monitoringAppDir}/prometheus/targets:/etc/prometheus/targets:ro"
            "${prometheusConfig}:/etc/prometheus/prometheus.yml:ro"
            "${alertRulesFile}:/etc/prometheus/alert-rules.yml:ro"
          ];

          labels = mkHomepageLabels {
            category = "Monitoring";
            name = "Prometheus";
            description = "Metrics Storage";
            icon = "prometheus.png";
            href = "http://localhost:${toString prometheusHostPort}";
          };

          exec = "--config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/prometheus --storage.tsdb.retention.time=30d --web.console.libraries=/usr/share/prometheus/console_libraries --web.console.templates=/usr/share/prometheus/consoles";

          extraConfig.Container = {
            Labels."logging.alloy" = "true";
            NoNewPrivileges = true;
          };
        };

        services.podman.containers.podman-exporter = {
          image = "quay.io/navidys/prometheus-podman-exporter:latest";
          autoStart = true;
          userNS = "keep-id";
          network = [ "monitoring.network" ];
          networkAlias = [ podmanExporterHost ];

          environment = {
            TZ = osConfig.time.timeZone;
            CONTAINER_HOST = "unix:///var/run/podman/podman.sock";
          };

          volumes = [
            "/run/podman/podman.sock:/var/run/podman/podman.sock:ro"
          ];

          extraConfig.Container = {
            SecurityLabelDisable = true;
            Labels."logging.alloy" = "true";
            NoNewPrivileges = true;
          };
        };

        services.podman.containers.grafana = {
          image = "grafana/grafana:latest";
          autoStart = true;
          userNS = "keep-id";
          network = [ "monitoring.network" ];
          networkAlias = [ grafanaHost ];
          ports = [ "${toString grafanaHostPort}:${toString grafanaContainerPort}" ];

          volumes = [
            "${monitoringAppDir}/grafana/data:/var/lib/grafana"
            "${datasourcesConfig}:/etc/grafana/provisioning/datasources/datasources.yml:ro"
          ];

          environment = {
            TZ = osConfig.time.timeZone;
            GF_USERS_ALLOW_SIGN_UP = "false";
          }
          // grafanaOidcEnv;

          labels = mkHomepageLabels {
            category = "Monitoring";
            name = "Grafana";
            description = "Metrics & Dashboards";
            icon = "grafana.png";
            href = "http://localhost:${toString grafanaHostPort}";
          };

          extraConfig.Container = {
            Labels."logging.alloy" = "true";
            NoNewPrivileges = true;
          };
        };

        services.podman.containers.loki = {
          image = "grafana/loki:latest";
          autoStart = true;
          userNS = "keep-id";
          network = [ "monitoring.network" ];
          networkAlias = [ lokiHost ];
          ports = [ "${toString lokiHostPort}:${toString lokiContainerPort}" ];

          environment.TZ = osConfig.time.timeZone;

          volumes = [
            "${monitoringAppDir}/loki:/loki"
            "${lokiConfig}:/etc/loki/local-config.yml:ro"
          ];

          labels = mkHomepageLabels {
            category = "Monitoring";
            name = "Loki";
            description = "Log Aggregation";
            icon = "grafana.png";
            href = "http://localhost:${toString lokiHostPort}";
          };

          extraConfig.Container = {
            Labels."logging.alloy" = "true";
            NoNewPrivileges = true;
          };
        };

        services.podman.containers.alloy = {
          image = "grafana/alloy:latest";
          autoStart = true;
          userNS = "keep-id";
          network = [ "monitoring.network" ];
          networkAlias = [ alloyHost ];
          ports = [ "${toString alloyHostPort}:${toString alloyContainerPort}" ];

          environment.TZ = osConfig.time.timeZone;

          volumes = [
            "${monitoringAppDir}/alloy/data:/var/lib/alloy"
            "${alloyConfig}:/etc/alloy/config.river:ro"
            "/var/log/journal:/var/log/journal:ro"
            "/etc/machine-id:/etc/machine-id:ro"
          ];

          exec = "run --server.http.listen-addr=0.0.0.0:${toString alloyContainerPort} --storage.path=/var/lib/alloy/data /etc/alloy/config.river";

          extraConfig.Container = {
            Labels."logging.alloy" = "true";
            NoNewPrivileges = true;
          };
        };
      };
    };
}
