{ config, ... }:
let
  domain = config.flake.meta.reverse-proxy.domain;
  port = config.flake.meta.reverse-proxy.ports.immich;
in
{
  flake.modules.nixos.homelab = {
    services.caddy.virtualHosts."immich.${domain}" = {
      useACMEHost = domain;
      extraConfig = ''
        import reverse_proxy_common

        request_body {
          max_size 50GB
        }

        reverse_proxy localhost:${toString port} {
          transport http {
            read_timeout 600s
            write_timeout 600s
          }
        }
      '';
    };
  };

  flake.modules.homeManager."${config.flake.meta.immich.user}@homelab" = hmArgs: {
    services.immich-podman = {
      enable = true;
      port = port;
      storageDir = "/var/lib/immich";
      dbPasswordFile = hmArgs.config.services.onepassword-secrets.secretPaths.immichDbPassword;
    };

    programs.onepassword-secrets.secrets.immichDbPassword = {
      path = ".secrets/immich/db_password";
      reference = "op://Homelab/Immich DB Password/credential";
      owner = config.flake.meta.immich.user;
      group = config.flake.meta.immich.group;
    };
  };
}
