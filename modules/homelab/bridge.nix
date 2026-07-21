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

  # Only process services that have a module defined (i.e., are enabled)
  # Services without a module are intentionally skipped — they exist as
  # homelab/service/*/default.nix templates but are not configured yet.
  enabledServices = lib.filterAttrs (name: svc: svc.module != null) config.flake.homelab.services;

  # Convert services attrset to list, preserving names
  servicesList = lib.mapAttrsToList (name: svc: { inherit name; } // svc) enabledServices;

  # Group services by their target user
  servicesByUser = lib.groupBy (svc: svc.user) servicesList;

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
      imports = map (svc: mkServiceModule svc.name svc) services;
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
