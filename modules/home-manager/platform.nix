{
  inputs,
  ...
}:
{
  flake.modules.darwin.base = {
    imports = [ inputs.home-manager.darwinModules.home-manager ];
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hm.old";
      verbose = true;
    };
  };

  flake.modules.nixos.base = {
    imports = [ inputs.home-manager.nixosModules.home-manager ];
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hm.old";
      verbose = true;
    };
  };
}
