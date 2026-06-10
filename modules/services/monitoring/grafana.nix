{ lib, config, ... }:
{
  flake.modules.homeManager."${config.flake.meta.monitoring.user}@homelab" =
    hmArgs@{ pkgs, ... }:
    let
      cfg = hmArgs.config.services.monitoring;
      grafanaPort = config.flake.meta.monitoring.grafana.port;
      grafanaDir = "${cfg.storageDir}/grafana";

      datasourcesConfig = pkgs.writeText "datasources.yml" (
        builtins.toJSON {
          apiVersion = 1;
          datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              url = "http://prometheus:9090";
              isDefault = true;
            }
            {
              name = "Loki";
              type = "loki";
              url = "http://loki:3100";
              isDefault = false;
            }
          ];
        }
      );
    in
    lib.mkIf cfg.enable {
      # TODO: remove secrets here, passing them as config or completely remove auth because grafana won't be accessible directly
      programs.onepassword-secrets.secrets = {
        grafanaAdminUser = {
          path = ".secrets/monitoring/grafana/admin-user";
          reference = "op://Homelab/Monitoring/Grafana/username";
        };
        grafanaAdminPassword = {
          path = ".secrets/monitoring/grafana/admin-password";
          reference = "op://Homelab/Monitoring/Grafana/password";
        };
      };

      services.podman.containers.grafana = {
        image = "grafana/grafana:latest";
        autoStart = true;
        userNS = "keep-id";
        network = [ "monitoring.network" ];
        networkAlias = [ "grafana" ];
        ports = [ "${toString grafanaPort}:3000" ];

        volumes = [
          "${grafanaDir}/data:/var/lib/grafana"
          "${datasourcesConfig}:/etc/grafana/provisioning/datasources/datasources.yml:ro"
        ];

        environment = {
          GF_USERS_ALLOW_SIGN_UP = "false";
        };

        secrets = {
          GF_SECURITY_ADMIN_USER = hmArgs.config.programs.onepassword-secrets.secretPaths.grafanaAdminUser;
          GF_SECURITY_ADMIN_PASSWORD =
            hmArgs.config.programs.onepassword-secrets.secretPaths.grafanaAdminPassword;
        };

        extraConfig.Container.NoNewPrivileges = true;
      };
    };
}
