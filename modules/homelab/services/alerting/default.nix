{
  flake.modules.nixos.homelab-alerting =
    { config, lib, ... }:
    {
      options.services.ntfy-notify = {
        url = lib.mkOption {
          type = lib.types.str;
          default = "https://ntfy.sh";
          description = "Base URL of the ntfy server.";
        };

        topic = lib.mkOption {
          type = lib.types.str;
          default = "xQE7urtm8kLErMDUUjGU3hvn8KKijmwyU6PkQMNs88EcunqhtFxFVfViXwzkvuqB";
          description = "ntfy topic for notifications.";
        };

        tokenFile = lib.mkOption {
          type = lib.types.str;
          default = "op://Homelab/Alerting/NTFY/token";
          description = "1Password reference to the ntfy access token.";
        };
      };

      config.services.onepassword-secrets.secrets.alertingNtfyToken = {
        path = "/run/secrets/alerting_ntfy_token";
        reference = config.services.ntfy-notify.tokenFile;
        group = "homelab-users";
        mode = "0640";
      };
    };
}
