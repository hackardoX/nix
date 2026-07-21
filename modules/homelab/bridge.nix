{ config, lib, ... }:
let
  # Build a home-manager module fragment for one service instance.
  #
  # `svc.module` can be either:
  #   - a function of home-manager module args: `hmArgs -> fragment`
  #   - a plain attrset
  #
  # If the result already has a `config` key (the shape our service
  # definition files produce, e.g. `{ config.services.homepage = {...}; }`),
  # it's already a well-formed module fragment that targets the right
  # option path — use it as-is, don't re-wrap it.
  #
  # Otherwise, treat the whole result as the *value* to assign to
  # `services.<name>` (the shorthand used e.g. by docker-socket-proxy:
  # `flake.homelab.services.docker-socket-proxy.module = { enable = true; ... };`).
  mkServiceModule =
    serviceName: svc: hmArgs:
    let
      result = if lib.isFunction svc.module then svc.module hmArgs else svc.module;
    in
    if builtins.isAttrs result && result ? config then
      result
    else
      { config.services.${serviceName} = result; };

  # Only process services that have a module defined (i.e., are enabled).
  # Services without a module are intentionally skipped — they exist as
  # homelab/service/*/default.nix templates but are not configured yet.
  enabledServices = lib.filterAttrs (name: svc: svc.module != null) config.flake.homelab.services;

  # Convert services attrset to list, preserving names.
  servicesList = lib.mapAttrsToList (name: svc: { inherit name; } // svc) enabledServices;

  # Group services by their target user.
  servicesByUser = lib.groupBy (svc: svc.user) servicesList;

  # Build home-manager.users structure directly.
  # Each user gets:
  #   - the shared "homelab" home-manager module, which declares the
  #     `services.<name>` options and generic implementation for every
  #     service (needed so the per-service overrides below have something
  #     to attach to);
  #   - their own services' specific overrides, collected together.
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
      imports = [
        config.flake.modules.homeManager.homelab
      ]
      ++ map (svc: mkServiceModule svc.name svc) services;
    }
  ) servicesByUser;
in
{
  # Build the homelab module with home-manager.users directly populated.
  # This ensures all services are automatically included when a host imports
  # flake.modules.nixos.homelab / flake.modules.darwin.homelab, without
  # needing separate service-specific modules.
  flake.modules.darwin.homelab = {
    home-manager.users = homeManagerUsers;
  };
  flake.modules.nixos.homelab = {
    home-manager.users = homeManagerUsers;
  };
}
