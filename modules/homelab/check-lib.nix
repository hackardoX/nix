{ lib, ... }:
let
  # Prints each failure and fails the build when the list is non-empty.
  mkCheck =
    pkgs: name: failures:
    let
      failureFile = pkgs.writeText "homelab-${name}-failures" (
        lib.concatMapStrings (f: "${f}\n") failures
      );
    in
    pkgs.runCommand "homelab-${name}" { } ''
      if [ -s ${failureFile} ]; then
        echo "homelab/${name}: ${toString (lib.length failures)} failure(s):" >&2
        sed 's/^/  - /' ${failureFile} >&2
        exit 1
      fi
      touch $out
    '';
in
{
  # Only mkCheck is shared. flake.lib is lazyAttrsOf anything, which deep-merges
  # attrsets, so a host config handle here would force the whole HomeLab-CI
  # config. Each check reads config.flake.nixosConfigurations.HomeLab-CI.config
  # itself, inside perSystem.checks.
  flake.lib.homelab.check.mkCheck = mkCheck;
}
