{ config, lib, ... }:
let
  host = config.flake.nixosConfigurations.HomeLab-CI.config;
  hmUsers = host.home-manager.users;

  # Home Manager's podman module already builds each quadlet into
  # $out/quadlets (the .container/.network files, with dependencies linked in).
  # Users without quadlets have an empty builtQuadlets.
  quadletUsers = lib.filterAttrs (_: h: h.services.podman.internal.builtQuadlets != { }) hmUsers;

  checkUser =
    name: h:
    let
      podman = h.services.podman.package;
      quadlets = lib.attrValues h.services.podman.internal.builtQuadlets;
    in
    ''
      echo "== quadlet dry-run for ${name}" >&2
      dir=$PWD/${name}
      mkdir -p $dir $dir-home
      ${lib.concatMapStrings (q: "cp -fL ${q}/quadlets/* $dir/\n") quadlets}
      # A failed copy stays fatal (errexit). Only the quadlet call is captured:
      # its exit status and stderr are checked below, not hidden.
      set +e
      QUADLET_UNIT_DIRS=$dir HOME=$dir-home XDG_CONFIG_HOME=$dir-home/config \
        ${podman}/libexec/podman/quadlet -dryrun -user >$dir.stdout 2>$dir.stderr
      rc=$?
      set -e
      if [ "$rc" -ne 0 ]; then
        echo "quadlet exited $rc for ${name}:" >&2
        cat $dir.stderr >&2
        failed=1
      elif grep -Eqi 'error|unsupported key' $dir.stderr; then
        echo "quadlet reported errors for ${name}:" >&2
        cat $dir.stderr >&2
        failed=1
      fi
    '';
in
{
  perSystem =
    { pkgs, ... }:
    {
      checks = lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "aarch64-linux") {
        "homelab/validate-quadlet" =
          if quadletUsers == { } then
            throw "homelab/validate-quadlet: no home-manager user has quadlets; the check would pass vacuously"
          else
            pkgs.runCommand "homelab-validate-quadlet" { } ''
              set -euo pipefail
              failed=0
              ${lib.concatStringsSep "\n" (lib.mapAttrsToList checkUser quadletUsers)}
              [ "$failed" -eq 0 ] || exit 1
              touch $out
            '';
      };
    };
}
