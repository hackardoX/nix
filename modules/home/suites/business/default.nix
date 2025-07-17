{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.suites.business;
in
{
  options = import (lib.snowfall.fs.get-file "modules/shared/suites-options/business/default.nix") {
    inherit lib namespace;
  };

  config = mkIf cfg.enable {
    ${namespace} = {
      security = {
        _1password = {
          enable = true;
        };
      };
    };
  };
}
