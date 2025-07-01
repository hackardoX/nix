{
  channels,
  inputs,
  writeShellApplication,
  ...
}:
let
  treefmtWrapper = inputs.treefmt-nix.lib.mkWrapper channels.nixpkgs ../../treefmt.nix;
in
writeShellApplication {
  name = "treefmt-nix";

  meta = {
    mainProgram = "treefmt-nix";
  };

  text = ''
    exec ${treefmtWrapper}/bin/treefmt "$@"
  '';
}
