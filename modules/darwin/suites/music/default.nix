{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.suites.music;
in
{
  options = import (lib.snowfall.fs.get-file "modules/shared/suites-options/music/default.nix") {
    inherit lib namespace;
  };

  config = lib.mkIf cfg.enable {
    ${namespace} = {
      programs.music.spicetify = enabled;
    };
  };
}
