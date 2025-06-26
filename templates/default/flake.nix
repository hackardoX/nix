{
  description = "NextJS Project Template";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
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
      git-hooks,
      nixpkgs,
      self,
      treefmt-nix,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSystem = nixpkgs.lib.genAttrs systems;
    in
    {

      checks = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          pre-commit-check = git-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              # Add here your pre-commit hooks: https://github.com/cachix/git-hooks.nix#hooks
              commitizen.enable = true;
              treefmt =
                let
                  myNix = pkgs.fetchFromGitHub {
                    owner = "andrea11";
                    repo = "nix";
                    rev = "main";
                    hash = "sha256-M5XFUuL8HtOiNPdF/xsrkqKTTCnVb03ok+DxWjKKrd0=";
                  };
                in
                {
                  enable = true;
                  settings.fail-on-change = false;
                  packageOverrides.treefmt = treefmt-nix.lib.mkWrapper pkgs "${myNix.outPath}/treefmt.nix";
                };
            };
          };
        }
      );

      devShells = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;

            packages = with pkgs; [
              # Add here your packages
            ];

            shellHook = ''
              ${self.checks.${system}.pre-commit-check.shellHook}

              echo 🔨 Welcome to your DevShell
            '';
          };
        }
      );
    };
}
