{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.suites.photo;
in
{
  options = import (lib.snowfall.fs.get-file "shared/suites-options/photo/default.nix") {
    inherit lib namespace;
  };
}
