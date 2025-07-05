{
  description = "Expo Project Template";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      git-hooks,
      nixpkgs,
      self,
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

      checks = forEachSystem (system: {
        pre-commit-check = git-hooks.lib.${system}.run {
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
            yamllint = {
              enable = true;
              excludes = [ "^pnpm\-lock\.ya?ml$" ];
            };
          };
        };
      });

      devShells = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;

            packages = with pkgs; [
              nodejs_latest
              nodePackages.npm
              nodePackages.yarn
              nodePackages.pnpm
              biome
              nodePackages.prettier
              nodePackages.eslint
              nodePackages.typescript
            ];

            shellHook = ''
              # START INIT BLOCK
              start_line=$(grep -n "# START INIT BLOCK" flake.nix | head -1 | cut -d: -f1)
              end_line=$(grep -n "# END INIT BLOCK" flake.nix | tail -1 | cut -d: -f1)
              if [ ! -d ".git" ]; then
                echo "Initializing git repository..."
                git init
              fi
              if [ ! -d "package.json" ]; then
                echo "Initializing Next.js project..."
                folder=$(basename "$PWD")
                npx create-expo-app@latest ./$folder
                mv $folder/!(.gitignore) .
                rm -rf $folder
              fi
              sed -i "''${start_line},''${end_line}d" flake.nix
              git add --all
              git commit --message "chore: initial commit"
              # END INIT BLOCK
              ${self.checks.${system}.pre-commit-check.shellHook}

              echo 🔨 Expo DevShell
            '';
          };
        }
      );
    };
}
