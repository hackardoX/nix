{
  description = "A custom flake for home-manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    mac-app-util.url = "github:hraban/mac-app-util";
  };

  outputs =
    {
      self,
      nixpkgs,
      mac-app-util,
      ...
    }:
    let
      inherit system user;
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      darwinModules = {
        custom-home-manager = _: {
          home-manager.darwinModules.home-manager = {
            useGlobalPkgs = true;
            users.${user} =
              {
                pkgs,
              }:
              let
                enumerate =
                  dir:
                  builtins.map (file: pkgs.callPackage (dir + "/" + file) { }) (
                    builtins.attrNames (builtins.readDir dir)
                  );
              in
              {
                home = {
                  packages = builtins.map (pkgName: pkgs.${pkgName}) builtins.import ./packages.nix;
                  file = builtins.import ./files;
                  stateVersion = "24.05";
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
        };
      };
    };
}
