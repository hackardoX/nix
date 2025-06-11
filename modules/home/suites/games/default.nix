{
  lib,
  namespace,
  ...
}:
{
  options = import (lib.snowfall.fs.get-file "modules/shared/suites-options/games/default.nix") {
    inherit lib namespace;
  };
}
