{
  config,
  inputs,
  lib,
  ...
}:
let
  mkBaseModule = hmPlatformModule: systemArgs: {
    imports = [ hmPlatformModule ];
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hm.old";
      verbose = true;
      users.${systemArgs.config.system.primaryUser}.imports = [
        config.flake.modules.homeManager.base
      ];
    };
  };

  mkPrimaryUserModule =
    moduleName: systemArgs:
    let
      primaryUser = systemArgs.config.system.primaryUser;
    in
    {
      home-manager.users.${primaryUser}.imports = [
        config.flake.modules.homeManager.${moduleName}
      ];
    };

  mkPlatformCoreModules =
    hmPlatformModule:
    lib.genAttrs (builtins.attrNames config.flake.modules.homeManager) mkPrimaryUserModule
    // {
      base = mkBaseModule hmPlatformModule;
    };
in
{
  flake.modules.darwin = mkPlatformCoreModules inputs.home-manager.darwinModules.home-manager;
  flake.modules.nixos = mkPlatformCoreModules inputs.home-manager.nixosModules.home-manager;
}
