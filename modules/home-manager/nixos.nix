{
  config,
  inputs,
  lib,
  ...
}:
# TODO: Refactor this into darwin.nix
let
  homeManagerModules = builtins.attrNames config.flake.modules.homeManager;
in
{
  flake.modules.nixos =
    lib.genAttrs homeManagerModules (
      moduleName: nixosArgs: {
        home-manager.users.${nixosArgs.config.system.primaryUser}.imports = [
          config.flake.modules.homeManager.${moduleName}
        ];
      }
    )
    // {
      base = nixosArgs: {
        imports = [ inputs.home-manager.nixosModules.home-manager ];

        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "hm.old";
          verbose = true;

          users.${nixosArgs.config.system.primaryUser}.imports = [
            config.flake.modules.homeManager.base
          ];
        };
      };
    };
}
