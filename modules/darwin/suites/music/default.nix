{
  lib,
  namespace,
  ...
}:
{
  options = import (lib.snowfall.fs.get-file "modules/shared/suites-options/music/default.nix") {
    inherit lib namespace;
  };
}
