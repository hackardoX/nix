{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.suites.social;
in
{
  options = import (lib.snowfall.fs.get-file "modules/shared/suites-options/social/default.nix") {
    inherit lib namespace;
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      "whatsapp"
    ];
  };
}
