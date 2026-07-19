{
  config,
  lib,
  pkgs,
  ...
}:
let
  cloudflaredStartScript = pkgs.writeShellScript "start-cloudflared" ''
    exec ${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run \
      --token-file "$CREDENTIALS_DIRECTORY"/token
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
        }
      '';
    };

    # TODO: Revisit when nixpkgs merges token-based tunnel support
    # https://github.com/NixOS/nixpkgs/pull/427964
    # At that point services.cloudflared.tunnels may replace this custom service.
    systemd.services.cloudflared = {
      wantedBy = [ "multi-user.target" ];
      after = [
        "network-online.target"
        "opnix-secrets.service"
      ];
      wants = [ "network-online.target" ];
      requires = [ "opnix-secrets.service" ];
      serviceConfig = {
        ExecStart = "${cloudflaredStartScript}";
        LoadCredential = "token:${config.services.onepassword-secrets.secretPaths.cloudflareTunnelTokenFile}";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        Restart = "on-failure";
        RestartSec = 5;
        DynamicUser = true;
      };
    };
  };
}
