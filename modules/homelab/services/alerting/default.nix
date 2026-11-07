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

        topicFile = lib.mkOption {
          type = lib.types.path;
          default = config.sops.secrets."alerting/ntfy_topic".path;
          description = ''
            File holding the ntfy topic. The topic is the only thing keeping a
            public ntfy server's notifications private, so it is a secret and
            consumers read it at runtime.
          '';
        };

        tokenFile = lib.mkOption {
          type = lib.types.str;
          default = "op://Homelab/Alerting/NTFY/token";
          description = "1Password reference to the ntfy access token.";
        };
      };

      config.sops.secrets = {
        "alerting/ntfy_token" = {
          group = "homelab-users";
          mode = "0640";
        };
        "alerting/ntfy_topic" = {
          group = "homelab-users";
          mode = "0640";
        };
      };
    };
}
