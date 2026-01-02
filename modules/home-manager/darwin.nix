{
  config,
  inputs,
  lib,
  ...
}:
let
  homeManagerModules = builtins.attrNames config.flake.modules.homeManager;
in
{
  flake.modules.darwin =
    lib.genAttrs homeManagerModules (
      moduleName: darwinArgs: {
        home-manager.users.${darwinArgs.config.system.primaryUser}.imports = [
          config.flake.modules.homeManager.${moduleName}
        ];
      }
    )
    // {
      base = darwinArgs: {
        imports = [ inputs.home-manager.darwinModules.home-manager ];

        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "hm.old";
          verbose = true;

          users.${darwinArgs.config.system.primaryUser}.imports = [
            config.flake.modules.homeManager.base
          ];
        };
      };
    };
}
