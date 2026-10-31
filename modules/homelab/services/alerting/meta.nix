{
  flake.modules.nixos.homelab-alerting =
    { lib, ... }:
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

      config.sops.secrets."alerting/ntfy_token" = {
        group = "homelab-users";
        mode = "0640";
      };
    };
}
