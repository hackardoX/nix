{
  lib,
  ...
}:
{
  flake.modules.nixos.ingress =
    nixosArgs:
    let
      domain = "homelab4.fun";
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
              "${domain}" = {
                service = "https://localhost:443";
                originRequest = {
                  noTLSVerify = true;
                  originServerName = domain;
                };
              };
              "*.${domain}" = {
                service = "https://localhost:443";
                originRequest = {
                  noTLSVerify = true;
                  originServerName = domain;
                };
              };
              "ssh.${domain}" = "ssh://localhost:22";
            };
            default = "http_status:404";
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

          extraConfig = lib.mkBefore ''
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
      };
    };
}
