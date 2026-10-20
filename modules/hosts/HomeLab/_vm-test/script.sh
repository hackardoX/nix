#!/bin/sh
# First smoke test for the HomeLab-CI VM. Spike: written, not yet executed.
# modules/hosts/HomeLab/vm-test.nix substitutes the @...@ placeholders with
# plain text lines from the evaluated host config and runs this inside the VM.
set -eu

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# retry SECONDS CMD...: run CMD once per second until it succeeds.
retry() {
  secs=$1
  shift
  i=0
  until "$@" >/dev/null 2>&1; do
    i=$((i + 1))
    if [ "$i" -ge "$secs" ]; then
      fail "timed out after ${secs}s: $*"
    fi
    sleep 1
  done
}

IMMICH_SECRET='@IMMICH_SECRET@'

# Every NixOS secret keeps its production owner, group and mode.
# Lines: PATH OWNER:GROUP:MODE (MODE as stat -c %a prints it).
while read -r path want; do
  got=$(stat -c '%U:%G:%a' "$path") || fail "cannot stat $path"
  [ "$got" = "$want" ] || fail "$path: $got != $want"
done <<'EOF'
@SECRETS@
EOF
echo "ok: secret owner, group and mode"

# A service user can read its own secret and not another service's.
runuser -s /bin/sh -u immich -- cat "$IMMICH_SECRET" >/dev/null ||
  fail "immich cannot read $IMMICH_SECRET"
if runuser -s /bin/sh -u tandoor -- cat "$IMMICH_SECRET" >/dev/null 2>&1; then
  fail "tandoor can read $IMMICH_SECRET"
fi
echo "ok: service users read only their own secrets"

# Authelia starts with the stubbed SMTP check, and writes the hashed OIDC secrets.
retry 300 systemctl is-active --quiet authelia-init.service
retry 300 systemctl is-active --quiet authelia-default.service
while read -r path; do
  [ -s "$path" ] || fail "empty or missing $path"
done <<'EOF'
@OIDC_SECRETS@
EOF
echo "ok: authelia active, hashed OIDC secrets written"

# Rootless podman: the user manager, home-manager and the quadlet units must
# come up on their own (no manual start). Service users have nologin shells,
# so the user manager is addressed with systemctl -M, not a login.
# Lines: NAME UID
while read -r name uid; do
  retry 300 systemctl is-active --quiet "user@$uid.service"
  retry 300 systemctl is-active --quiet "home-manager-$name.service"
done <<'EOF'
@USERS@
EOF
# Lines: NAME UNIT
while read -r name unit; do
  retry 900 systemctl --user -M "$name@" is-active "$unit"
done <<'EOF'
@USER_UNITS@
EOF
# Lines: FILE
while read -r path; do
  [ -s "$path" ] || fail "empty or missing $path"
done <<'EOF'
@USER_FILES@
EOF
echo "ok: user managers, home-manager, podman units and secret files"

# Report only: failed units are findings, not failures of this smoke test.
# `|| true` is used here and nowhere else.
echo "report: systemctl --failed"
systemctl --failed --no-legend || true
while read -r name uid; do
  echo "report: systemctl --user --failed for $name"
  systemctl --user -M "$name@" --failed --no-legend || true
done <<'EOF'
@USERS@
EOF
