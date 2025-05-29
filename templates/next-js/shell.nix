{
  self,
  mkShell,
  pkgs,
  system,
  ...
}:
mkShell {
  buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;

  packages = with pkgs; [
    nodejs
    nodePackages.npm
    nodePackages.yarn
    nodePackages.pnpm
    biome
    nodePackages.prettier
    nodePackages.eslint
    nodePackages.typescript
  ];

  shellHook = ''
    ${self.checks.${system}.pre-commit-check.shellHook}

    echo 🔨 Node DevShell


  '';
}
