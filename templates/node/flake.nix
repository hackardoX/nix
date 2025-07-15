{
  description = "NodeJS Project Template";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      flake-utils,
      nixpkgs,
      pre-commit-hooks,
      self,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {

        checks = {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              biome.enable = true;
              check-yaml.enable = true;
              commitizen.enable = true;
              eslint.enable = true;
              nixfmt-rfc-style.enable = true;
              sort-simple-yaml = {
                enable = true;
                excludes = [ "^pnpm\-lock\.ya?ml$" ];
              };
              # TODO: Check when https://github.com/cachix/git-hooks.nix/pull/594 is merged
              # trufflehog.enable = true;
              yamlfmt = {
                enable = true;
                excludes = [ "^pnpm\-lock\.ya?ml$" ];
              };
            };
          };
        };

        devShells = {
          default = pkgs.mkShell {
            packages = with pkgs; [
              nodejs
              nodePackages.npm
              nodePackages.yarn
              nodePackages.pnpm
              biome
              nodePackages.prettier
              nodePackages.eslint
              nodePackages.typescript
              pre-commit
            ];

            shellHook = ''
              ${self.checks.${system}.pre-commit-check.shellHook}

              echo 🔨 Node DevShell
            '';
          };
        };
      }
    );
}
