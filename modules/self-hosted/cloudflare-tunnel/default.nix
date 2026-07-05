{
  config,
  lib,
  pkgs,
  ...
}:
let
  cloudflaredStartScript = pkgs.writeShellScript "start-cloudflared" ''
    exec ${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token "$(cat "$CREDENTIALS_DIRECTORY"/token)"
  '';
in
{
  flake.modules.nixos.homelab = {
    services = {
      onepassword-secrets.secrets.cloudflareTunnelTokenFile = {
        path = "/run/secrets/cloudflared/token";
        reference = "op://Homelab/Cloudflare Tunnel/token";
        mode = "0400";
      };

      caddy.extraConfig = lib.mkBefore ''
        {
          servers {
            trusted_proxies cloudflare
            trusted_proxies_strict
            client_ip_headers Cf-Connecting-Ip X-Forwarded-For
          }
        }

        (reverse_proxy_common) {
          import common_headers
          import geoblock
          import rate_limit_common
          import tls_hardened
          import auth_protected

          request_body {
            max_size 10MB
          }

          encode

          header_up X-Real-IP {client_ip}
        }
      '';
    };

    systemd.services.cloudflared = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        ExecStart = "${cloudflaredStartScript}";
        LoadCredential = "token:${config.services.onepassword-secrets.secretPaths.cloudflareTunnelTokenFile}";
        Restart = "on-failure";
        RestartSec = 5;
        DynamicUser = true;
      };
    };
  };
}
