{
  config,
  inputs,
  lib,
  ...
}:
let
  hostSubmodule = lib.types.submodule {
    options = {
      module = lib.mkOption { type = lib.types.deferredModule; };
      nixpkgs = lib.mkOption {
        type = lib.types.raw;
        default = inputs.nixpkgs;
      };
    };
  };

  nixosSystems = lib.mapAttrs (
    _: cfg: lib.nixosSystem { modules = [ cfg.module ]; }
  ) config.configurations.nixos;

  darwinSystems = lib.mapAttrs (
    _: cfg: inputs.darwin.lib.darwinSystem { modules = [ cfg.module ]; }
  ) config.configurations.darwin;

  mkHostChecks =
    kind: systems:
    lib.mkMerge (
      lib.mapAttrsToList (name: cfg: {
        ${cfg.config.nixpkgs.hostPlatform.system}.${"configurations/${kind}/${name}"} =
          cfg.config.system.build.toplevel;
      }) systems
    );
in
{
  options = {
    configurations.nixos = lib.mkOption { type = lib.types.lazyAttrsOf hostSubmodule; };
    configurations.darwin = lib.mkOption { type = lib.types.lazyAttrsOf hostSubmodule; };
  };

  config.flake = {
    nixosConfigurations = nixosSystems;
    darwinConfigurations = darwinSystems;
    checks = lib.mkMerge [
      (mkHostChecks "nixos" nixosSystems)
      (mkHostChecks "darwin" darwinSystems)
    ];
  };
}
