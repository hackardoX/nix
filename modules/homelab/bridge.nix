{ config, lib, ... }:
let
  # Build a home-manager module fragment for one service instance.
  #
  # `flake.homelab.services.<name>.module` is a `deferredModule`-typed
  # option: reading it back ALWAYS yields `{ imports = [ <raw defs> ]; }`,
  # regardless of how many files defined it (even just one). So `svc.module`
  # itself is never the value you wrote directly — it's that wrapper.
  # We unwrap it here to get at the raw definitions.
  #
  # Each raw definition can be either:
  #   - a function of home-manager module args: `hmArgs -> fragment`
  #     (e.g. homepage's `hmArgs: { config.services.homepage = {...}; }`)
  #   - a plain attrset (e.g. docker-socket-proxy's
  #     `{ enable = true; network = "homepage"; }`)
  mkServiceModule =
    serviceName: svc: hmArgs:
    let
      rawDefs = svc.module.imports;

      resolveDef =
        def:
        let
          result = if lib.isFunction def then def hmArgs else def;
        in
        # If the resolved value already has a `config` key, it's already a
        # full module fragment targeting the right option path (e.g.
        # homepage's `{ config.services.homepage = {...}; }`) — use as-is,
        # preserving any other top-level keys (options, assertions, etc).
        # Otherwise, the whole value is shorthand for `services.<name>`'s
        # config (e.g. docker-socket-proxy's `{ enable = true; ... }`).
        if builtins.isAttrs result && result ? config then
          result
        else
          { services.${serviceName} = result; };
    in
    {
      imports = map resolveDef rawDefs;
    };

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
