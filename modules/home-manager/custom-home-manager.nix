{
  home-manager,
  mac-app-util,
}:
{
  user,
  pkgs,
  lib,
  config,
  ...
}:
home-manager.darwinModules.home-manager {
  inherit config lib pkgs;
  home-manager = {
    useGlobalPkgs = true;
    users.${user} =
      {
        pkgs,
        ...
      }:
      let
        enumerate = 
          dir: builtins.foldl' (allPrograms: program: allPrograms // program) {} 
            (builtins.map (file: builtins.import (builtins.concatStringsSep "/" [dir file]) { inherit user; }) 
              (builtins.attrNames (builtins.readDir dir)));
      in
      {
        home = {
          packages = builtins.map (pkgName: pkgs.${pkgName}) builtins.import ./packages.nix;
          file = builtins.import ./files;
          stateVersion = "24.05";
          enableDebugInfo = true;
        };

        imports = [
          mac-app-util.homeManagerModules.default
        ];

        programs = enumerate ./programs;

        # Marked broken Oct 20, 2022 check later to remove this
        # https://github.com/nix-community/home-manager/issues/3344
        # manual.manpages.enable = false;

        targets.darwin =
          let
            allDefaults = builtins.import ./defaults.nix;
          in
          {
            defaults = allDefaults.defaults;
            currentHostDefaults = allDefaults.currentHostDefaults;
          };
      };
  };
}
