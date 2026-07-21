{ config, lib, ... }:
let
  mkServiceModule =
    serviceName: svc: hmArgs:
    let
      result = if lib.isFunction svc.module then svc.module hmArgs else svc.module;
      serviceConfig = result.config or { };
      rest = removeAttrs result [ "config" ];
    in
    rest
    // {
      services.${serviceName} = serviceConfig;
    };

  mkServiceUserModule =
    serviceName: systemArgs:
    let
      svc = config.flake.homelab.services.${serviceName};
      user = svc.user;
      allUsers = builtins.attrNames systemArgs.config.users.users;
    in
    {
      assertions = [
        {
          assertion = builtins.elem user allUsers;
          message = "homelab service '${serviceName}' references user '${user}', but that user does not exist in config.users.users.";
        }
      ];
      home-manager.users.${user}.imports = [
        (mkServiceModule serviceName svc)
      ];
    };

  # Creates an attrset of modules like:
  #   { service-homepage = ...; service-immich = ...; ... }
  # Each module routes a service's home-manager config into its designated
  # per-user scope (e.g. home-manager.users.homepage.imports = ...).
  platformServiceModules = lib.mapAttrs' (
    name: _: lib.nameValuePair "service-${name}" (mkServiceUserModule name)
  ) config.flake.homelab.services;
in
{
  # Flatten all service-* modules into the existing "homelab" module so they
  # are automatically imported when a host imports flake.modules.nixos.homelab
  # without needing to list each service individually (e.g. service-homepage,
  # service-immich, ...).
  flake.modules.darwin.homelab = lib.mkMerge (lib.attrValues platformServiceModules);
  flake.modules.nixos.homelab = lib.mkMerge (lib.attrValues platformServiceModules);
}
