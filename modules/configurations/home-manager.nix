{
  config,
  lib,
  inputs,
  ...
}:
{
  options.configurations.homeManager = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.deferredModule;
  };

  config.flake = {
    homeConfigurations = lib.flip lib.mapAttrs config.configurations.homeManager (
      _name: { module }: inputs.homeManager.lib.homeManagerSystem { modules = [ module ]; }
    );

    checks =
      config.flake.homeConfigurations
      |> lib.mapAttrsToList (
        name: homeManager: {
          ${homeManager.config.nixpkgs.hostPlatform.system} = {
            "configurations/homeManager/${name}" = homeManager.config.system.build.toplevel;
          };
        }
      )
      |> lib.mkMerge;
  };
}
