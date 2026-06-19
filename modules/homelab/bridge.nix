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

  platformServiceModules = lib.mapAttrs' (
    name: _: lib.nameValuePair "service-${name}" (mkServiceUserModule name)
  ) config.flake.homelab.services;
in
{
  flake.modules.darwin = platformServiceModules;
  flake.modules.nixos = platformServiceModules;
}
