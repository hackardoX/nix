{
  description = "My flake";
  inputs = {
    # android-nixpkgs = {
    #   url = "github:tadfisher/android-nixpkgs";
    #   inputs = {
    #     flake-utils.follows = "flake-utils";
    #     nixpkgs.follows = "nixpkgs";
    #   };
    # };
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
    nix-mineral = {
      url = "github:cynicsketch/nix-mineral";
      inputs = {
        flake-compat.follows = "";
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
      };
    };
    nix-rosetta-builder = {
      url = "github:cpick/nix-rosetta-builder";
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
    # nix4vscode = {
    #   url = "github:nix-community/nix4vscode";
    #   inputs = {
    #     nixpkgs.follows = "nixpkgs";
    #     systems.follows = "systems";
    #   };
    # };
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

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
