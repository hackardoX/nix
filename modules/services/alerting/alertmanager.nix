{ lib, config, ... }:
{
  flake.modules.homeManager."${config.flake.meta.alerting.user}@homelab" =
    hmArgs@{ pkgs, ... }:
    let
      cfg = hmArgs.config.services.alerting;
      alertmanagerHostPort = config.flake.meta.alerting.alertmanager.hostPort;
      alertmanagerContainerPort = config.flake.meta.alerting.alertmanager.containerPort;
      alertmanagerNtfyHost = config.flake.meta.alerting.alertmanagerNtfy.host;
      alertmanagerNtfyContainerPort = config.flake.meta.alerting.alertmanagerNtfy.containerPort;
      alertmanagerDir = "${cfg.storageDir}/alertmanager";

      alertmanagerConfig = pkgs.writeText "alertmanager.yml" (
        builtins.toJSON {
          global = {
            resolve_timeout = "5m";
          };

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
                  url = "http://${alertmanagerNtfyHost}:${toString alertmanagerNtfyContainerPort}/hook";
                  send_resolved = true;
                }
              ];
            }
          ];
        }
      );
    in
    lib.mkIf cfg.enable {
      services.podman.networks.alerting.driver = "bridge";

      services.podman.containers.alertmanager = {
        image = "prom/alertmanager:latest";
        autoStart = true;
        userNS = "keep-id";
        monitoring.enable = true;
        network = [
          "alerting.network"
          "monitoring.network"
        ];
        networkAlias = [ "alertmanager" ];
        ports = [ "${toString alertmanagerHostPort}:${toString alertmanagerContainerPort}" ];

        volumes = [
          "${alertmanagerDir}/data:/alertmanager"
          "${alertmanagerConfig}:/etc/alertmanager/alertmanager.yml:ro"
        ];

        exec = "--config.file=/etc/alertmanager/alertmanager.yml --storage.path=/alertmanager";

        extraConfig.Container.NoNewPrivileges = true;
      };
    };
}
