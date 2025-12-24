{
  perSystem =
    {
      config,
      inputs',
      pkgs,
      ...
    }:
    {
      devShells.default = pkgs.mkShell {
        name = "dotfiles";

        buildInputs = config.pre-commit.settings.enabledPackages;

        packages =
          builtins.attrValues {
            inherit (pkgs)
              git
              nixfmt-tree
              ripgrep
              sops
              ;
          }
          ++ [
            inputs'.deploy-rs.packages.default
            inputs'.helix.packages.default # a editor if I'm dumb and remove it somehow
          ];

        shellHook = ''
          ${config.pre-commit.settings.shellHook}
        '';
      };
    };
}
