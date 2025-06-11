{
  lib,
  namespace,
  ...
}:
{
  options = import (lib.snowfall.fs.get-file "modules/shared/suites-options/photo/default.nix") {
    inherit lib namespace;
  };
}
