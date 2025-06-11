{
  mkShell,
  pkgs,
  ...
}:
let
  kamal = pkgs.buildRubyGem {
    pname = "kamal";
    gemName = "kamal";
    version = "2.6.1";
    src = pkgs.fetchurl {
      url = "https://rubygems.org/downloads/kamal-2.6.1.gem";
      sha256 = "1fc4a95d5a483b4bb49c1745e52f1e1f8c0829483e63903dc4f9a6148bf5652a";
    };
  };
in
mkShell {

  packages = with pkgs; [
    ruby
    (ruby.withPackages (
      ps: with ps; [
        kamal
      ]
    ))
  ];

  shellHook = ''

    echo 🔨 Ruby DevShell - `${pkgs.ruby}/bin/ruby --version`


  '';
}
