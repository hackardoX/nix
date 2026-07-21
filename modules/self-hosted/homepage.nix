{ config, ... }:
let
  domain = config.flake.meta.reverse-proxy.domain;
  port = config.flake.meta.reverse-proxy.ports.homepage;
in
{
  flake.modules.nixos.homelab = {
    # Redirect root domain to Homepage
    services.caddy.virtualHosts."${domain}" = {
      extraConfig = ''
        import reverse_proxy_common
        redir https://homepage.${domain}{uri}
      '';
    };

    # Homepage subdomain
    services.caddy.virtualHosts."homepage.${domain}" = {
      extraConfig = ''
        import auth_protected
        import reverse_proxy_common
        reverse_proxy localhost:${toString port}
      '';
    };
  };

  flake.homelab.services.docker-socket-proxy.module.enable = true;
  flake.homelab.services.homepage.module = hmArgs: {
    config = {
      services.homepage = {
        enable = true;
        port = port;

        settings = {
          title = "Homelab";
          description = "Self-hosted services dashboard";
          theme = "dark";
          color = "slate";
          statusStyle = "dot";
          useEqualHeights = true;
        };

        widgets = [
          {
            resources = {
              cpu = true;
              memory = true;
              label = "System";
            };
          }
          {
            resources = {
              disk = "/";
              label = "Storage";
            };
          }
          {
            resources = {
              network = "eth0";
              label = "Network";
            };
          }
        ];
      };
    };
  };
}
