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
      startAsUserService = true;
      backupFileExtension = "hm.old";
      verbose = true;
    };

    systemd.user.services.home-manager = {
      wantedBy = [ "default.target" ];
      before = [ "default.target" ];
    };
  };
}
