{
  config,
  ...
}:
let
  domain = config.flake.meta.reverse-proxy.domain;
  hosts = config.flake.meta.reverse-proxy.hosts;
in
{
  flake.modules.nixos.homelab-ingress =
    nixosArgs@{
      config,
      lib,
      ...
    }:
    let
      tunnelUuid = config.services.cloudflared.tunnelUuid;
    in
    {
      options.services.cloudflared.tunnelUuid = lib.mkOption {
        type = lib.types.str;
        default = "7ba3afe7-dd5d-4972-9035-6e181d2beedb";
        description = "Cloudflare tunnel UUID.";
      };

      config = {
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
                "${hosts.ssh}" = "ssh://localhost:22";
              };
              default = "https://localhost:443";
            };
          };

          caddy = {
            globalConfig = lib.mkAfter ''
              servers {
                trusted_proxies combine {
                  cloudflare
                  static 127.0.0.1/32 ::1/128
                }
                trusted_proxies_strict
                client_ip_headers Cf-Connecting-Ip
              }
            '';
          };
        };

        systemd.services."cloudflared-tunnel-${tunnelUuid}" = {
          after = [ "opnix-secrets.service" ];
          wants = [ "opnix-secrets.service" ];
        };
      };
    };
}
