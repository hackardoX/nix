{
  config,
  lib,
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
    homebrew = {
      brews = [
        # Stremio dependencies https://github.com/erfansamandarian/stremio-mac
        "ffmpeg"
        "icu4c@75"
        "mpv"
        "node"
        "openssl@3"
        "qt@5"
      ];

      masApps = mkIf config.${namespace}.tools.homebrew.masEnable {
        # "Infuse" = 1136220934;
        # "iMovie" = 408981434;
        # "DaVinci Resolve" = 571213070
      };
    };
  };
}
