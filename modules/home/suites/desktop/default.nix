{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkDefault mkIf;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.suites.desktop;
in
{
  options = import (lib.snowfall.fs.get-file "modules/shared/suites-options/desktop/default.nix") {
    inherit lib namespace;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      raycast
    ];

    ${namespace}.programs.graphical.apps = {
      aldente = mkDefault enabled;
    };
  };
}
