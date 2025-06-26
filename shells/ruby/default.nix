{
  mkShell,
  pkgs,
  ...
}:
let
  gems = pkgs.bundlerEnv {
    name = "gems";
    inherit (pkgs) ruby;
    gemfile = ./Gemfile;
    lockfile = ./Gemfile.lock;
    gemset = ./gemset.nix;
  };
in
mkShell {

  packages = with pkgs; [
    ruby
    (ruby.withPackages (
      ps: with ps; [
        bundix
        gems
      ]
    ))
  ];

  shellHook = ''

    echo 🔨 Ruby DevShell - `${pkgs.ruby}/bin/ruby --version`


  '';
}
