{
  description = "Blank Project Template";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    flake-utils = {
      url = "github:numtide/flake-utils";
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

            packages = [
              (treefmt-nix.lib.mkWrapper pkgs "${myNix.outPath}/treefmt.nix")
              # Add here your packages
            ];

            shellHook = ''
              # START INIT BLOCK
              start_line=$(grep -n "# START INIT BLOCK" flake.nix | head -1 | cut -d: -f1)
              end_line=$(grep -n "# END INIT BLOCK" flake.nix | tail -1 | cut -d: -f1)
              if [ ! -d ".git" ]; then
                echo "Initializing git repository..."
                git init
              fi
              sed -i "''${start_line},''${end_line}d" flake.nix
              git add --all
              git commit --message "chore: initial commit"
              # END INIT BLOCK
              ${self.checks.${system}.pre-commit-check.shellHook}

              echo 🔨 Welcome to your DevShell
            '';
          };
        };
      }
    );
}
