{
  description = "A very basic flake";
  inputs = {
    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    op-shell-plugins = {
      url = "github:1password/shell-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    custom-homebrew-formulas = {
      url = "github:hackardox/homebrew-formulas";
      flake = false;
    };
    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        # Optional inputs removed
        gitignore.follows = "";
        flake-compat.follows = "";
      };
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-tap-krunkit = {
      url = "github:slp/homebrew-krun";
      flake = false;
    };
    nix-homebrew = {
      # TODO: revert to "github:zhaofengli/nix-homebrew" when https://github.com/zhaofengli/nix-homebrew/pull/117/files is merged
      url = "github:yeradon/nix-homebrew";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix4vscode = {
      url = "github:nix-community/nix4vscode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs = {
      url = "github:nixos/nixpkgs?ref=nixos-unstable";
    };
    opnix = {
      url = "github:brizzbuzz/opnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      inherit (inputs) snowfall-lib treefmt-nix;

      lib = snowfall-lib.mkLib {
        inherit inputs;
        src = ./.;

        snowfall = {
          meta = {
            name = "setup-flake";
            title = "My custom MacOS configuration flake";
          };

          namespace = "aaccardo";
        };
      };
    in
    lib.mkFlake {
      channels-config = {
        # allowBroken = true;
        allowUnfree = true;
        # showDerivationWarnings = [ "maintainerless" ];
        permittedInsecurePackages = [ ];
      };

      overlays = with inputs; [
        nix4vscode.overlays.default
      ];

      homes.modules = with inputs; [
        catppuccin.homeModules.catppuccin
        inputs.op-shell-plugins.hmModules.default
        nix-index-database.homeModules.nix-index
        opnix.homeManagerModules.default
      ];

      systems.modules = {
        darwin = with inputs; [
          nix-homebrew.darwinModules.nix-homebrew
          (
            {
              config,
              namespace,
              ...
            }:
            {
              nix-homebrew = {
                inherit (config.${namespace}.tools.homebrew) enable;
                user = config.${namespace}.user.name;
                taps = {
                  "homebrew/homebrew-core" = homebrew-core;
                  "homebrew/homebrew-cask" = homebrew-cask;
                  "hackardox/homebrew-formulas" = custom-homebrew-formulas;
                  "slp/homebrew-krunkit" = homebrew-tap-krunkit;
                };
                mutableTaps = false;
                autoMigrate = true;
              };
            }
          )
          opnix.darwinModules.default
          spicetify-nix.darwinModules.spicetify
        ];
      };

      templates = {
        default.description = "Default template";
        expo.description = "Expo template";
        next-js.description = "NextJS template";
        node.description = "Node template";
        python.description = "Python template";
        rust.description = "Rust template";
      };

      # deploy = lib.mkDeploy { inherit (inputs) self; };

      outputs-builder = channels: {
        formatter = treefmt-nix.lib.mkWrapper channels.nixpkgs ./treefmt.nix;
      };
    };
}
