{
  lib,
  namespace,
  ...
}:
{
  options = import (lib.snowfall.fs.get-file "shared/suites-options/games/default.nix") {
    inherit lib namespace;
  };
}
