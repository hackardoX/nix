{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.suites.networking;
in
{
  options = import (lib.snowfall.fs.get-file "modules/shared/suites-options/networking/default.nix") {
    inherit lib namespace;
  };

  config = mkIf cfg.enable {
    ${namespace} = {
      services = {
        tailscale = lib.mkDefault enabled;
      };

      system = {
        networking = lib.mkDefault enabled;
      };
    };
  };
}
