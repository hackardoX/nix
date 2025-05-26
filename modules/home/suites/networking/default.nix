{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.suites.networking;
in
{
  options = import (lib.snowfall.fs.get-file "shared/suites-options/networking/default.nix") {
    inherit lib namespace;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      openssh
      ssh-copy-id
    ];
  };
}
