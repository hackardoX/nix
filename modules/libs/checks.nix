{ lib, ... }:
let
  # Derivation names cannot contain "/", so "homelab/ports" becomes "homelab-ports".
  drvName = name: lib.replaceStrings [ "/" ] [ "-" ] name;

  # Prints each failure and fails the build when the list is non-empty.
  # `name` is the full check name, as it appears in `checks`.
  mkCheck =
    pkgs: name: failures:
    let
      failureFile = pkgs.writeText "${drvName name}-failures" (
        lib.concatMapStrings (f: "${f}\n") failures
      );
    in
    pkgs.runCommand (drvName name) { } ''
      if [ -s ${failureFile} ]; then
        echo "${name}: ${toString (lib.length failures)} failure(s):" >&2
        sed 's/^/  - /' ${failureFile} >&2
        exit 1
      fi
      touch $out
    '';

  # NixOS writes these units as drop-ins over the packaged unit
  # (overrideStrategy = asDropinIfExists), so the packaged file, when there is
  # one, is the base and the generated text follows it. Appending is the same as
  # a drop-in: systemd merges repeated sections in order.
  unitDir =
    host: pkgs: units:
    pkgs.runCommand "systemd-units" { } ''
      mkdir -p $out
      ${lib.concatMapStrings (n: ''
        base=
        for pkg in ${lib.concatStringsSep " " host.systemd.packages}; do
          if [ -f "$pkg/lib/systemd/system/${n}" ]; then base=$pkg/lib/systemd/system/${n}; fi
        done
        {
          if [ -n "$base" ]; then cat "$base"; echo; fi
          cat ${pkgs.writeText n host.systemd.units.${n}.text}
        } > $out/${n}
      '') units}
    '';

  # systemd-analyze wants /run/systemd, which the build sandbox does not have
  # and cannot create. So verify runs in a chroot under a directory we own,
  # inside a user namespace. The chroot holds systemd's closure, the unit
  # files, and the ExecStart binaries (verify checks that they exist and are
  # executable; it does not run them).
  systemdClosure = host: pkgs: pkgs.closureInfo { rootPaths = [ host.systemd.package ]; };

  # `systemd-analyze verify` on the given system units (each module passes the
  # units it owns). `host` is the evaluated NixOS config the units come from.
  # Any output from verify fails the check; nothing is filtered.
  mkSystemdCheck =
    host: pkgs: name: units:
    let
      unitFiles = unitDir host pkgs units;
      closure = systemdClosure host pkgs;
    in
    lib.throwIf (units == [ ]) "${name}: no units given" (
      pkgs.runCommand "${drvName name}"
        {
          nativeBuildInputs = [
            host.systemd.package
            pkgs.util-linux
            pkgs.coreutils
            pkgs.gnugrep
            pkgs.gnused
            pkgs.gawk
          ];
        }
        ''
          set -euo pipefail
          root=$PWD/root
          mkdir -p $root/nix/store $root/run $root/tmp/units
          for p in $(cat ${closure}/store-paths); do
            cp -an "$p" $root/nix/store/ || { echo "failed to copy closure path $p" >&2; exit 1; }
          done
          cp -an ${unitFiles}/. $root/tmp/units/ || { echo "failed to copy unit files" >&2; exit 1; }
          # grep exits 1 when nothing matches; the empty-file check below decides.
          { grep -h '^Exec[A-Za-z]*=' ${unitFiles}/* || true; } \
            | sed -E 's/^Exec[A-Za-z]*=[-@+!:]*//' | awk '{ print $1 }' \
            | { grep '^/nix/store/' || true; } | sort -u > execs.txt
          if [ ! -s execs.txt ] && grep -q '^ExecStart=' ${unitFiles}/*; then
            echo "no /nix/store ExecStart binaries found, but units have ExecStart entries" >&2
            exit 1
          fi
          while IFS= read -r e; do
            mkdir -p "$root$(dirname "$e")"
            cp -an "$e" "$root$e" || { echo "failed to copy exec binary $e" >&2; exit 1; }
          done < execs.txt

          units=()
          for u in $root/tmp/units/*; do
            units+=("/tmp/units/$(basename "$u")")
          done

          # The search path is our units plus systemd's own base units (in the
          # copied closure). Any message at all is a failure: nothing is filtered.
          log=$PWD/verify.log
          # Only the verify call may fail without stopping the build: its exit
          # status is captured and checked below.
          set +e
          SYSTEMD_UNIT_PATH=/tmp/units:${host.systemd.package}/example/systemd/system \
            unshare --user --map-root-user chroot $root \
            ${host.systemd.package}/bin/systemd-analyze verify --man=no "''${units[@]}" >$log 2>&1
          rc=$?
          set -e
          echo "systemd-analyze verify: exit $rc, ''${#units[@]} units" >&2
          if [ "$rc" -ne 0 ] || [ -s $log ]; then
            echo "systemd-analyze verify reported failures (exit $rc):" >&2
            sed 's/^/  /' $log >&2
            exit 1
          fi
          touch $out
        ''
    );
in
{
  # Only functions are shared. flake.lib is lazyAttrsOf anything, which deep-merges
  # attrsets, so a host config handle here would force the whole HomeLab-CI
  # config. Each check passes its own evaluated host config to mkSystemdCheck,
  # inside perSystem.checks.
  flake.lib.checks = {
    inherit mkCheck mkSystemdCheck;
  };
}
