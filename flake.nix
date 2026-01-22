{
  description = "My flake";
  inputs.self.submodules = true;
  inputs = {
    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
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
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs = {
        flake-compat.follows = "";
        utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
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
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    import-tree = {
      url = "github:vic/import-tree";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs = {
        pre-commit.follows = "git-hooks";
        nixpkgs.follows = "nixpkgs";
      };
    };
    make-shell = {
      url = "github:nicknovitski/make-shell";
      inputs.flake-compat.follows = "";
    };
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };
    nix4vscode = {
      url = "github:nix-community/nix4vscode";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };
    nixpkgs = {
      url = "github:nixos/nixpkgs?ref=nixos-unstable";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
    };
    op-shell-plugins = {
      url = "github:1password/shell-plugins";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };
    opnix = {
      url = "github:brizzbuzz/opnix";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };
    refjump-nvim = {
      flake = false;
      url = "github:mawkler/refjump.nvim";
    };
    smart-scrolloff-nvim = {
      flake = false;
      url = "github:tonymajestro/smart-scrolloff.nvim";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };
    systems = {
      url = "github:nix-systems/default";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vim-autoread = {
      flake = false;
      url = "github:djoshea/vim-autoread/24061f84652d768bfb85d222c88580b3af138dab";
    };
  };

  /*
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
  */

  nixConfig = {
    # abort-on-warn = true;
    extra-experimental-features = [ "pipe-operators" ];
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
