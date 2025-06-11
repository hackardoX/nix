{
  mkShell,
  pkgs,
  ...
}:
mkShell {
  # Packages included in the environment
  buildInputs = [ pkgs.nodejs_24 ];

  # Run when the shell is started up
  shellHook = ''
    echo 🔨 Node DevShell - node `${pkgs.nodejs_24}/bin/node --version`
  '';
}
