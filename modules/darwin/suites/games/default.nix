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
  options = import (lib.snowfall.fs.get-file "modules/shared/suites-options/games/default.nix") {
    inherit lib namespace;
  };

  config = mkIf cfg.enable {
    homebrew = {
      casks = [
        # "moonlight"
        # "steam"
      ];
    };
  };
}
