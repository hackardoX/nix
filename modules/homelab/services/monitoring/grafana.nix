{ lib, config, ... }:
{
  flake.modules.homeManager.homelab =
    hmArgs@{ pkgs, ... }:
    let
      cfg = hmArgs.config.services.monitoring;
      domain = config.flake.meta.reverse-proxy.domain;
      grafanaHost = config.flake.meta.monitoring.grafana.host;
      grafanaContainerPort = config.flake.meta.monitoring.grafana.containerPort;
      grafanaHostPort = config.flake.meta.monitoring.grafana.hostPort;
      prometheusHost = config.flake.meta.monitoring.prometheus.host;
      prometheusPort = config.flake.meta.monitoring.prometheus.containerPort;
      lokiHost = config.flake.meta.monitoring.loki.host;
      lokiPort = config.flake.meta.monitoring.loki.containerPort;
      grafanaDir = "${cfg.appDir}/grafana";

      datasourcesConfig = pkgs.writeText "datasources.yml" (
        builtins.toJSON {
          apiVersion = 1;
          datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              url = "http://${prometheusHost}:${prometheusPort}";
              isDefault = true;
            }
            {
              name = "Loki";
              type = "loki";
              url = "http://${lokiHost}:${lokiPort}";
              isDefault = false;
            }
          ];
        }
      );
    in
    lib.mkIf cfg.enable {
      services.podman.containers.grafana = {
        image = "grafana/grafana:latest";
        autoStart = true;
        userNS = "keep-id";
        network = [ "monitoring.network" ];
        networkAlias = [ grafanaHost ];
        ports = [ "${toString grafanaHostPort}:${toString grafanaContainerPort}" ];

        volumes = [
          "${grafanaDir}/data:/var/lib/grafana"
          "${datasourcesConfig}:/etc/grafana/provisioning/datasources/datasources.yml:ro"
        ];

        environment = {
          GF_USERS_ALLOW_SIGN_UP = "false";
        }
        // lib.optionalAttrs (cfg.grafana.oidcClientSecretFile != null) {
          GF_AUTH_GENERIC_OAUTH_ENABLED = "true";
          GF_AUTH_GENERIC_OAUTH_NAME = "Authelia";
          GF_AUTH_GENERIC_OAUTH_CLIENT_ID = config.flake.meta.oidc-clients.grafana.clientId;
          GF_AUTH_GENERIC_OAUTH_SCOPES = "openid profile email";
          GF_AUTH_GENERIC_OAUTH_AUTH_URL = "https://auth.${domain}/api/oidc/authorization";
          GF_AUTH_GENERIC_OAUTH_TOKEN_URL = "https://auth.${domain}/api/oidc/token";
          GF_AUTH_GENERIC_OAUTH_API_URL = "https://auth.${domain}/api/oidc/userinfo";
          GF_AUTH_GENERIC_OAUTH_ALLOW_SIGN_UP = "true";
          GF_AUTH_GENERIC_OAUTH_AUTO_LOGIN = "true";
          GF_SERVER_ROOT_URL = "https://grafana.${domain}";
        };

        secrets = lib.optionalAttrs (cfg.grafana.oidcClientSecretFile != null) {
          GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET = cfg.grafana.oidcClientSecretFile;
        };

        labels = config.flake.lib.mkHomepageLabels {
          category = "Monitoring";
          name = "Grafana";
          description = "Metrics & Dashboards";
          icon = "grafana.png";
          href = "http://localhost:${toString grafanaHostPort}";
        };

        extraConfig.Container.NoNewPrivileges = true;
      };
    };
}
