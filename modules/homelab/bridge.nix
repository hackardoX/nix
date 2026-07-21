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

  # Group services by their target user
  servicesByUser = lib.groupBy (name: svc: svc.user) config.flake.homelab.services;

  # Build home-manager.users structure directly
  # Each user gets all their services' imports collected together
  homeManagerUsers = lib.mapAttrs (
    user: services:
    let
      allUsers = builtins.attrNames config.users.users;
    in
    {
      assertions = [
        {
          assertion = builtins.elem user allUsers;
          message = "homelab services reference user '${user}', but that user does not exist in config.users.users.";
        }
      ];
      imports = lib.mapAttrsToList (name: svc: mkServiceModule name svc) services;
    }
  ) servicesByUser;
in
{
  # Build the homelab module with home-manager.users directly populated
  # This ensures all services are automatically included when a host imports
  # flake.modules.nixos.homelab without needing separate service-* modules.
  flake.modules.darwin.homelab = {
    home-manager.users = homeManagerUsers;
  };
  flake.modules.nixos.homelab = {
    home-manager.users = homeManagerUsers;
  };
}
