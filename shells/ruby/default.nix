{
  mkShell,
  pkgs,
  ...
}:
mkShell {
  packages = with pkgs; [
    ruby
  ];

  shellHook = ''

    echo 🔨 Ruby DevShell


  '';
}
