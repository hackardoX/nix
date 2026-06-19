{
  flake.homelab.services.monitoring = hmArgs: {
    config = {
      enable = true;
      prometheus.alertRules = {
        container_health = {
          rules = [
            {
              alert = "ContainerDown";
              expr = "up == 0";
              for = "5m";
              labels = {
                severity = "critical";
              };
              annotations = {
                summary = "Container {{ $labels.instance }} is down";
                description = "Container has been unreachable for more than 5 minutes";
              };
            }
          ];
        };

        resource_usage = {
          rules = [
            {
              alert = "HighCPUUsage";
              expr = "rate(container_cpu_usage_seconds_total[5m]) > 0.8";
              for = "5m";
              labels = {
                severity = "critical";
              };
              annotations = {
                summary = "High CPU usage on {{ $labels.instance }}";
                description = "CPU usage is above 80% for 5 minutes";
              };
            }
            {
              alert = "HighMemoryUsage";
              expr = "container_memory_usage_bytes / container_memory_limit_bytes > 0.85";
              for = "5m";
              labels = {
                severity = "critical";
              };
              annotations = {
                summary = "High memory usage on {{ $labels.instance }}";
                description = "Memory usage is above 85% for 5 minutes";
              };
            }
            {
              alert = "LowDiskSpace";
              expr = "node_filesystem_avail_bytes / node_filesystem_size_bytes < 0.15";
              for = "5m";
              labels = {
                severity = "critical";
              };
              annotations = {
                summary = "Low disk space on {{ $labels.instance }}";
                description = "Disk space is below 15% (85% used)";
              };
            }
          ];
        };
      };
    };

    flake.homelab.services.alerting = hmArgs: {
      programs.onepassword-secrets.secrets.ntfyToken = {
        path = ".secrets/alerting/ntfy/token";
        reference = "op://Homelab/Alerting/ntfy/token";
      };

      config = {
        enable = true;
        ntfyTokenFile = hmArgs.config.programs.onepassword-secrets.secretPaths.ntfyToken;
      };
    };
  };
}
