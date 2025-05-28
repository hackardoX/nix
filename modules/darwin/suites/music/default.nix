{
  lib,
  namespace,
  ...
}:
{
  options = import (lib.snowfall.fs.get-file "shared/suites-options/music/default.nix") {
    inherit lib namespace;
  };
}
