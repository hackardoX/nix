{ config, ... }:
{
  flake.modules.nixos.homelab-security = nixosArgs: {
    services = {
      authelia = {
        instances.default = {
          settings.session.redis.host = "/run/redis-authelia/redis.sock";
          secrets.sessionSecretFile =
            nixosArgs.config.services.onepassword-secrets.secretPaths.autheliaSessionSecret;
        };
      };

      redis.servers.authelia = {
        enable = true;
        port = 0;
      };
    };

    users.users.${config.flake.meta.users.authelia.name}.extraGroups = [
      "redis-authelia"
    ];

    boot.initrd.impermanence.persist.files = [
      "/var/lib/redis-authelia/dump.rdb"
    ];

    systemd.services.redis-authelia = {
      before = [ "authelia-default.service" ];
      wantedBy = [ "authelia-default.service" ];
    };
  };
}
