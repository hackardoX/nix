{ config, lib, ... }:
{
  config.flake.meta.users.authelia = {
    name = "authelia-default";
    description = "System user running Authelia.";
  };

  options.flake.meta.oidc-clients = lib.mkOption {
    type = lib.types.attrsOf config.flake.lib.types.oidcClient;
    default = { };
    description = "OIDC clients shared between Authelia and the services that consume them.";
  };
}
