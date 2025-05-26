{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.suites.games;
in
{
  options = import (lib.snowfall.fs.get-file "shared/suites-options/games/default.nix") {
    inherit lib namespace;
  };
}
