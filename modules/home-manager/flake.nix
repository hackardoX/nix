{
  description = "A custom flake for home-manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      mac-app-util,
      ...
    }:
    let
      darwinSystems = [ "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs darwinSystems f;
      mkModules = system: {
        custom-home-manager = import ./custom-home-manager.nix {
          inherit
            home-manager
            mac-app-util
            system
            ;
        };
      };
    in
    {
      darwinModules = (forAllSystems mkModules);
    };
}
