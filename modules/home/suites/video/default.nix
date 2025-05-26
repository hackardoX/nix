{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.suites.video;

in
{
  options = import (lib.snowfall.fs.get-file "shared/suites-options/video/default.nix") {
    inherit lib namespace;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; lib.optionals stdenv.hostPlatform.isDarwin [ iina ];

    ${namespace}.programs = {
      graphical.apps = {
        # obs = lib.mkDefault enabled;
      };
    };
  };
}
