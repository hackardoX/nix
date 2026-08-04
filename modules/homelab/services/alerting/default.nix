{
  config,
  ...
}:
let
  ntfy = config.flake.meta.ntfy;
in
{
  flake.meta.ntfy = {
    url = "https://ntfy.sh";
    topic = "xQE7urtm8kLErMDUUjGU3hvn8KKijmwyU6PkQMNs88EcunqhtFxFVfViXwzkvuqB";
    tokenFile = "op://Homelab/Alerting/NTFY/token";
  };

  flake.modules.nixos.homelab-alerting = {
    services.onepassword-secrets.secrets = {
      alertingNtfyToken = {
        path = "/run/secrets/alerting_ntfy_token";
        reference = ntfy.tokenFile;
        group = "homelab-users";
        mode = "0640";
      };
    };
  };
}
