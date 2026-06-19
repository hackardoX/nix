{ config, ... }:
let
  domain = config.flake.meta.reverse-proxy.domain;
  port = config.flake.meta.reverse-proxy.ports.tandoor;
  appSubDomain = "recipes";
in
{
  flake.modules.nixos.homelab = {
    services.caddy.virtualHosts."${appSubDomain}.${domain}" = {
      useACMEHost = domain;
      extraConfig = ''
        import reverse_proxy_common
        reverse_proxy localhost:${toString port}
      '';
    };
  };

  flake.homelab.services.tandoor = hmArgs: {
    config = {
      enable = true;
      port = port;
      secretKeyFile = hmArgs.config.services.onepassword-secrets.secretPaths.tandoorSecretKeyPath;
      database.passwordFile =
        hmArgs.config.services.onepassword-secrets.secretPaths.tandoorDbPasswordPath;
    };

    programs.onepassword-secrets.secrets = {
      tandoorSecretKeyPath = {
        path = "/run/secrets/tandoor/secret_key";
        reference = "op://Homelab/Tandoor/Secret Key/credential";
        owner = config.flake.meta.tandoor.user;
        group = config.flake.meta.tandoor.group;
      };

      tandoorDbPasswordPath = {
        path = "/run/secrets/tandoor/db_password";
        reference = "op://Homelab/Tandoor/Database/password";
        owner = config.flake.meta.tandoor.user;
        group = config.flake.meta.tandoor.group;
      };
    };
  };
}
