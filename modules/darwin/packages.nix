{ pkgs }:

with pkgs;
let shared-packages = builtins.import ../shared/packages.nix { inherit pkgs; }; in
shared-packages ++ [
  aldente
  dockutil
  raycast
]
