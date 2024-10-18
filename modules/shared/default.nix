{ config, pkgs, ... }:

{

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = true;
      allowInsecure = false;
      allowUnsupportedSystem = true;
    };

    overlays =
      # Apply each overlay found in the /overlays directory
      let path = ../../overlays; in with builtins;
      builtins.map (n: builtins.import (path + ("/" + n)))
          (builtins.filter (n: match ".*\\.nix" n != null ||
                      builtins.pathExists (path + ("/" + n + "/default.nix")))
                  (builtins.attrNames (builtins.readDir path)));
  };
}