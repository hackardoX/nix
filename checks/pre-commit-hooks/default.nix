{
  inputs,
  pkgs,
  ...
}:
let
  inherit (inputs) git-hooks;
in
git-hooks.lib.${pkgs.system}.run {
  src = ../..;
  hooks = {
    clang-tidy.enable = true;
    # TODO: see how enable this even if sops is disable
    pre-commit-hook-ensure-sops.enable = false;
    conventional-pre-commit.enable = true;
    treefmt = {
      enable = true;
      settings.fail-on-change = false;
      packageOverrides.treefmt = inputs.treefmt-nix.lib.mkWrapper pkgs ../../treefmt.nix;
    };
  };
}
