{
  lib,
  namespace,
  ...
}:
{
  options = import (lib.snowfall.fs.get-file "shared/suites-options/photo/default.nix") {
    inherit lib namespace;
  };
}
