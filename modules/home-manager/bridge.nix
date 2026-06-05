{
  config,
  inputs,
  lib,
  ...
}:
let
  homeManagerModules = builtins.attrNames config.flake.modules.homeManager;

  parseModuleName =
    name:
    let
      parts = builtins.split "@" name;
    in
    if builtins.length parts == 3 then
      {
        user = builtins.elemAt parts 0;
        moduleName = builtins.elemAt parts 2;
      }
    else
      {
        user = null;
        moduleName = name;
      };

  mkHomeManagerModule =
    entryName: systemArgs:
    let
      parsed = parseModuleName entryName;
      primaryUser = systemArgs.config.system.primaryUser;
      user = if parsed.user != null then parsed.user else primaryUser;
      moduleName = parsed.moduleName;

      allUsers = builtins.attrNames systemArgs.config.users.users;
    in
    {
      assertions = [
        {
          assertion = builtins.elem user allUsers;
          message = "home-manager module '${moduleName}' references user '${user}', but that user does not exist in config.users.users.";
        }
      ];

      home-manager.users.${user}.imports = [
        config.flake.modules.homeManager.${moduleName}
      ];
    };

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

  mkPlatformModules =
    hmPlatformModule:
    lib.genAttrs homeManagerModules mkHomeManagerModule
    // {
      base = mkBaseModule hmPlatformModule;
    };
in
{
  flake.modules.darwin = mkPlatformModules inputs.home-manager.darwinModules.home-manager;
  flake.modules.nixos = mkPlatformModules inputs.home-manager.nixosModules.home-manager;
}
