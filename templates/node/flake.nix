{
  description = "NodeJS Project Template";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      pre-commit-hooks,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSystem = nixpkgs.lib.genAttrs systems;

      pkgsForEach = nixpkgs.legacyPackages;
    in
    {

      checks = forEachSystem (system: {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            biome.enable = true;
            check-yaml.enable = true;
            commitizen.enable = true;
            eslint.enable = true;
            nixfmt.enable = true;
            sort-simple-yaml.enable = true;
            # TODO: Check when https://github.com/cachix/git-hooks.nix/pull/594 is merged
            # trufflehog.enable = true;
            yamlfmt.enable = true;
            yamllint = {
              enable = true;
              excludes = [ "^pnpm\-lock\.ya?ml$" ];
            };
          };
        };
      });

      devShells = forEachSystem (system: {
        default = pkgsForEach.${system}.callPackage ./shell.nix { inherit self; };
      });
    };
}
