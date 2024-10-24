{
  description = "A flake that provides a dock configuration module";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      darwinSystems = [ "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs (darwinSystems) f;
      mkModules = system: {
        custom-dock = import ./custom-dock.nix { };
      };
    in
    {
      darwinModules = forAllSystems mkModules;
    };
}

# Original source: https://gist.github.com/antifuchs/10138c4d838a63c0a05e725ccd7bccdd
