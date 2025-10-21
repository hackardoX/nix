{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.suites.video;

in
{
  options = import (lib.snowfall.fs.get-file "modules/shared/suites-options/video/default.nix") {
    inherit lib namespace;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      openshot-qt
    ];

    ${namespace}.programs = {
      graphical.apps = {
        # obs = lib.mkDefault enabled;
      };
    };
  };
}
