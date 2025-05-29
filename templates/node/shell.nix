{
  mkShell,
  pkgs,
  ...
}:
mkShell {
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

    echo 🔨 Node DevShell


  '';
}
