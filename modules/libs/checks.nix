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

  # `systemd-analyze verify` on the given system units (each module passes the
  # units it owns). `host` is the evaluated NixOS config the units come from.
  # Any output from verify fails the check; nothing is filtered.
  #
  # verify needs a writable /run: systemd's manager creates /run/systemd at
  # startup with a non-recursive mkdir. The build sandbox has no /run and cannot
  # create one, and user namespaces are not permitted on the CI runner
  # (unshare fails writing uid_map), so no chroot is possible either. proot is
  # ptrace-based and needs neither: it binds a directory we own onto /run in
  # verify's view of the filesystem.
  #
  # The ExecStart binaries verify checks for exist in /nix/store because the
  # unit text references them. `unitFiles` is an input, and its output keeps
  # those store paths as references, so they are in the check's input closure
  # and present in the sandbox.
  mkSystemdCheck =
    host: pkgs: name: units:
    let
      unitFiles = unitDir host pkgs units;
      unitPaths = map (u: "${unitFiles}/${u}") units;
    in
    lib.throwIf (units == [ ]) "${name}: no units given" (
      pkgs.runCommand "${drvName name}"
        {
          nativeBuildInputs = [
            host.systemd.package
            pkgs.proot
            pkgs.coreutils
            pkgs.gnugrep
            pkgs.gnused
            pkgs.gawk
          ];
        }
        ''
          set -euo pipefail
          # grep exits 1 when nothing matches; the empty-file check below decides.
          { grep -h '^Exec[A-Za-z]*=' ${unitFiles}/* || true; } \
            | sed -E 's/^Exec[A-Za-z]*=[-@+!:]*//' | awk '{ print $1 }' \
            | { grep '^/nix/store/' || true; } | sort -u > execs.txt
          if [ ! -s execs.txt ] && grep -q '^ExecStart=' ${unitFiles}/*; then
            echo "no /nix/store ExecStart binaries found, but units have ExecStart entries" >&2
            exit 1
          fi

          # The search path is our units plus systemd's own base units (in the
          # build inputs). Any message at all is a failure: nothing is filtered.
          log=$PWD/verify.log
          # The writable /run that proot binds onto /run (see above).
          mkdir -p $PWD/run
          # Only the verify call may fail without stopping the build: its exit
          # status is captured and checked below. PROOT_VERBOSE=-1 keeps proot's
          # own warnings out of the log, so only verify's output can fail it.
          set +e
          SYSTEMD_UNIT_PATH=${unitFiles}:${host.systemd.package}/example/systemd/system \
            PROOT_VERBOSE=-1 proot -b "$PWD/run:/run" \
            ${host.systemd.package}/bin/systemd-analyze verify --man=no \
            ${lib.escapeShellArgs unitPaths} >$log 2>&1
          rc=$?
          set -e
          echo "systemd-analyze verify: exit $rc, ${toString (lib.length units)} units" >&2
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
