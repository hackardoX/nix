{
  home-manager,
  mac-app-util,
  ...
}:
{
  user,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    home-manager.darwinModules.home-manager
  ];

  config = {
    home-manager = {
      useGlobalPkgs = true;
      users.${user} =
        let
          enumerate =
            dir:
            builtins.foldl' (allPrograms: program: allPrograms // program) { } (
              builtins.map (
                file:
                builtins.import (builtins.concatStringsSep "/" [
                  dir
                  file
                ]) { inherit user; }
              ) (builtins.attrNames (builtins.readDir dir))
            );
        in
        {
          imports = [
            mac-app-util.homeManagerModules.default
          ];

          home = {
            packages = builtins.import ./packages.nix { inherit pkgs; };
            file = builtins.import ./files.nix { inherit user lib; };
            stateVersion = "24.05";
          };

          programs = enumerate ./programs;

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
  };
}
