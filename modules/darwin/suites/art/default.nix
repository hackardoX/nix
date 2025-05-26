{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.suites.art;
in
{
  options = import (lib.snowfall.fs.get-file "shared/suites-options/art/default.nix") {
    inherit lib namespace;
  };

  config = mkIf cfg.enable {
    homebrew = {
      casks = [
        # "blender"
        # "gimp"
        # "inkscape"
        # "mediainfo"
      ];

      masApps = mkIf config.${namespace}.tools.homebrew.masEnable {
        # "Pixelmator" = 407963104;
      };
    };
  };
}
