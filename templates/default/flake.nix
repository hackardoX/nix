{
  description = "NextJS Project Template";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/default";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      flake-utils,
      git-hooks,
      nixpkgs,
      self,
      treefmt-nix,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        myNix = pkgs.fetchFromGitHub {
          owner = "andrea11";
          repo = "nix";
          rev = "main";
          hash = "sha256-M5XFUuL8HtOiNPdF/xsrkqKTTCnVb03ok+DxWjKKrd0=";
        };
      in
      {
        checks = {
          pre-commit-check = git-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              # Add here your pre-commit hooks: https://github.com/cachix/git-hooks.nix#hooks
              commitizen.enable = true;
              treefmt = {
                enable = true;
                settings.fail-on-change = false;
                packageOverrides.treefmt = treefmt-nix.lib.mkWrapper pkgs "${myNix.outPath}/treefmt.nix";
              };
            };
          };
        };

        devShells = {
          default = pkgs.mkShell {
            buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;

            packages = with pkgs; [
              (treefmt-nix.lib.mkWrapper pkgs "${myNix.outPath}/treefmt.nix")
              # Add here your packages
            ];

            shellHook = ''
              ${self.checks.${system}.pre-commit-check.shellHook}

              echo 🔨 Welcome to your DevShell
            '';
          };
        };
      }
    );
}
