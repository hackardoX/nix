{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      flake-utils,
      git-hooks,
      nixpkgs,
      poetry2nix,
      self,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        checks = {
          pre-commit-check = git-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              check-yaml.enable = true;
              commitizen.enable = true;
              nixfmt-rfc-style.enable = true;
              ruff-check.enable = true;
              ruff-format.enable = true;
              sort-simple-yaml.enable = true;
              yamlfmt.enable = true;
            };
          };
        };

        packages =
          let
            inherit (poetry2nix.lib.mkPoetry2Nix { pkgs = pkgs.${system}; }) mkPoetryApplication;
          in
          {
            default = mkPoetryApplication { projectDir = self; };
          };

        devShells =
          let
            inherit (poetry2nix.lib.mkPoetry2Nix { pkgs = pkgs.${system}; }) mkPoetryEnv;
          in
          {
            default = pkgs.${system}.mkShellNoCC {
              packages = with pkgs.${system}; [
                (mkPoetryEnv { projectDir = self; })
                poetry
              ];

              shellHook = ''
                ${self.checks.${system}.pre-commit-check.shellHook}

                echo 🔨 Python DevShell
              '';
            };
          };
      }
    );
}
