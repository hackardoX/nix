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
          cloudflared = {
            enable = true;
            tunnels.${tunnelUuid} = {
              credentialsFile = nixosArgs.config.sops.secrets."ingress/cloudflare_tunnel_credentials".path;
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

        sops.secrets."ingress/cloudflare_tunnel_credentials" = {
          mode = "0400";
        };
      };
    };
}
