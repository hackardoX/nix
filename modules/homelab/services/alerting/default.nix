{ lib, config, ... }:
{
  flake.meta.alerting = {
    user = "alerting";
    group = "alerting";
    alertmanager = {
      host = "alertmanager";
      containerPort = 9093;
      hostPort = 9093;
    };
    alertmanagerNtfy = {
      host = "alertmanager-ntfy";
      containerPort = 8000;
      hostPort = 8000;
    };
  };

  flake.modules.nixos.homelab = {
    users.users.${config.flake.meta.alerting.user} = {
      isNormalUser = true;
      extraGroups = [
        config.flake.meta.alerting.group
      ];
      linger = true;
    };
  };

  flake.homelab.services.alerting.user = config.flake.meta.alerting.user;

  flake.modules.homeManager.homelab = {
    options.services.alerting = {
      enable = lib.mkEnableOption "Alerting stack (Alertmanager, alertmanager-ntfy)";

      storageDir = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/containers/alerting";
        description = "Base directory for alerting data";
      };

      ntfyTokenFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to file containing the ntfy access token";
      };

      ntfyTopic = lib.mkOption {
        type = lib.types.str;
        default = "homelab-alerts";
        description = "ntfy topic to send alerts to";
      };
    };
  };
}
