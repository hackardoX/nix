{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.suites.music;
in
{
  options = import (lib.snowfall.fs.get-file "modules/shared/suites-options/music/default.nix") {
    inherit lib namespace;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      spotify
    ];
  };
}
