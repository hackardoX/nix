{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf optionals;

  cfg = config.${namespace}.suites.development;
in
{
  options = import (lib.snowfall.fs.get-file "shared/suites-options/development/default.nix") {
    inherit lib namespace;
  };

  config = mkIf cfg.enable {
    homebrew = {
      casks = optionals cfg.dockerEnable [ "docker" ] ++ optionals cfg.aiEnable [ "ollamac" ];

      masApps = mkIf config.${namespace}.tools.homebrew.masEnable {
        # "Xcode" = 497799835;
      };
    };
  };
}
