{
  inputs,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    let
      treefmtWrapper = inputs.treefmt-nix.lib.mkWrapper pkgs ./_treefmt.nix;
    in
    {
      packages.treefmt-nix = pkgs.writeShellApplication {
        name = "treefmt-nix";

        meta = {
          mainProgram = "treefmt-nix";
        };

        text = ''
          exec ${treefmtWrapper}/bin/treefmt "$@"
        '';
      };
    };
}
