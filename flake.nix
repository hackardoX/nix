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
      url = "https://flakehub.com/f/nix-darwin/nix-darwin/0.1";
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
    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    };
    disko = {
      url = "https://flakehub.com/f/nix-community/disko/1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    flake-parts = {
      url = "https://flakehub.com/f/hercules-ci/flake-parts/0.1";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    git-hooks = {
      url = "https://flakehub.com/f/cachix/git-hooks.nix/0.1";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        # Optional inputs removed
        gitignore.follows = "";
        flake-compat.follows = "";
      };
    };
    home-manager = {
      url = "https://flakehub.com/f/nix-community/home-manager/0.1";
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
      url = "https://flakehub.com/f/nix-community/lanzaboote/1";
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
    nixpkgs = {
      url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
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
      url = "https://flakehub.com/f/numtide/treefmt-nix/0.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vim-autoread = {
      flake = false;
      url = "github:djoshea/vim-autoread/24061f84652d768bfb85d222c88580b3af138dab";
    };
  };

  # nixConfig = {
  #   abort-on-warn = true;
  #   extra-experimental-features = [ "pipe-operators" ];
  # };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
