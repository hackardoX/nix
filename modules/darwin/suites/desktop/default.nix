{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.suites.desktop;
in
{
  options = import (lib.snowfall.fs.get-file "shared/suites-options/desktop/default.nix") {
    inherit lib namespace;
  };

  config = mkIf cfg.enable {
    homebrew = {
      casks = [
        # "bitwarden"
        # "ghostty"
        # "gpg-suite"
        # "hammerspoon"
        # "launchcontrol"
        # "sf-symbols"
        # "xquartz"
      ];

      masApps = mkIf config.${namespace}.tools.homebrew.masEnable {
        # "PopClip" = 445189367;
      };
    };
  };
}
