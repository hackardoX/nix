{
  config,
  lib,
  ...
}:
{
  flake.modules.nixos.homelab-ingress =
    nixosArgs:
    let
      domain = config.flake.meta.reverse-proxy.domain;
      tunnelUuid = "7ba3afe7-dd5d-4972-9035-6e181d2beedb";
    in
    {
      services = {
        onepassword-secrets.secrets.cloudflareTunnelCredentials = {
          path = "/run/secrets/cloudflared/credentials.json";
          reference = "op://HomeLab/Cloudflare/homelab4.fun/${tunnelUuid}.json";
          mode = "0400";
        };

        cloudflared = {
          enable = true;
          tunnels.${tunnelUuid} = {
            credentialsFile =
              nixosArgs.config.services.onepassword-secrets.secretPaths.cloudflareTunnelCredentials;
            originRequest = {
              noTLSVerify = true;
              originServerName = domain;
            };
            ingress = {
              "ssh.${domain}" = "ssh://localhost:22";
            };
            default = "https://localhost:443";
          };
        };

        caddy = {
          globalConfig = lib.mkAfter ''
            servers {
              trusted_proxies cloudflare
              trusted_proxies_strict
              client_ip_headers Cf-Connecting-Ip X-Forwarded-For
            }
          '';
        };
      };

      systemd.services."cloudflared-tunnel-${tunnelUuid}" = {
        after = [ "opnix-secrets.service" ];
        wants = [ "opnix-secrets.service" ];
      };
    };
}
