{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.suites.art;
in
{
  options = import (lib.snowfall.fs.get-file "modules/shared/suites-options/art/default.nix") {
    inherit lib namespace;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ ];
  };
}
