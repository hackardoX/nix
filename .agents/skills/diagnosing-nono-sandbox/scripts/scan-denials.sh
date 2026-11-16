#!/usr/bin/env bash
# Summarize sandbox denial signatures found in a harness's logs.
#
#   scan-denials.sh --list
#   scan-denials.sh [--days N] [--top N] <harness> [extra log file or dir ...]
#
# Output: one line per distinct signature, "count  first-seen  last-seen  signature", with
# timestamps, ids, pids and hashes stripped so repeats collapse. Sources that exist but cannot be
# read (the sandbox hides them) are printed as UNREADABLE: that is a gap in the evidence, not a
# clean bill of health.
set -uo pipefail

days=14
top=30
state=${XDG_STATE_HOME:-$HOME/.local/state}
data=${XDG_DATA_HOME:-$HOME/.local/share}

# Permission-style failures plus nono's command-policy denials and Seatbelt kernel denials.
signature='EPERM|EACCES|EROFS|Operation not permitted|Permission denied|command policy denied|Sandbox: .*deny\('

if [ "${1:-}" = "--list" ]; then
  # Each configured harness has a `nono-profile-<name>` exporter (sandbox/default.nix).
  IFS=: read -ra dirs <<<"$PATH"
  for d in "${dirs[@]}"; do
    for f in "$d"/nono-profile-*; do [ -x "$f" ] && echo "${f##*/nono-profile-}"; done
  done | sort -u
  exit 0
fi

harness=
extra=()
while [ $# -gt 0 ]; do
  case $1 in
  --days)
    days=$2
    shift 2
    ;;
  --top)
    top=$2
    shift 2
    ;;
  *)
    if [ -z "$harness" ]; then harness=$1; else extra+=("$1"); fi
    shift
    ;;
  esac
done
[ -n "$harness" ] || {
  echo "usage: scan-denials.sh [--days N] [--top N] <harness> [extra paths...]" >&2
  exit 2
}

# Log locations per harness. Add a case when a new harness is added to programs.nono.harnesses.
case $harness in
opencode)
  sources=("$data/opencode/log")
  ;;
claude-code)
  # CLAUDE_CONFIG_DIR of the sandboxed harness (sandbox/claude-code.nix), plus the MCP logs
  # Claude Code keeps in the user cache.
  sources=("$state/claude-code-sandbox/debug" "$state/claude-code-sandbox/projects"
    "$HOME/Library/Caches/claude-cli-nodejs")
  ;;
*)
  sources=()
  [ ${#extra[@]} -gt 0 ] || {
    echo "No built-in log locations for '$harness': pass log files or dirs as extra arguments." >&2
    exit 2
  }
  ;;
esac
sources+=(${extra[@]+"${extra[@]}"})

# unreadable = the sandbox hides it (it or an ancestor answers "not permitted"), missing = absent.
status() {
  local p=$1 err
  while [ "$p" != / ]; do
    err=$(ls -d "$p" 2>&1 >/dev/null)
    case $err in
    *"not permitted"*)
      echo unreadable
      return
      ;;
    "") break ;;
    esac
    p=$(dirname "$p")
  done
  if [ ! -e "$1" ]; then echo missing; elif [ -d "$1" ] && ! ls "$1" >/dev/null 2>&1; then echo unreadable; else echo ok; fi
}

skipped=0
files=$(mktemp) && trap 'rm -f "$files"' EXIT
for s in "${sources[@]}"; do
  st=$(status "$s")
  if [ "$st" = unreadable ]; then
    echo "UNREADABLE: $s (hidden from this session; rerun from an unsandboxed shell or pass the file)"
  elif [ "$st" = missing ]; then
    echo "MISSING: $s"
  elif [ -d "$s" ]; then
    find "$s" -type f \( -name '*.log' -o -name '*.txt' -o -name '*.jsonl' \) -mtime "-$days" 2>/dev/null >>"$files"
    skipped=$((skipped + $(find "$s" -type f \( -name '*.log' -o -name '*.txt' -o -name '*.jsonl' \) -mtime "+$days" 2>/dev/null | wc -l)))
  else
    echo "$s" >>"$files"
  fi
done

echo "files scanned: $(wc -l <"$files" | tr -d ' ') (modified in the last $days days; $skipped older skipped, use --days)"

# macOS Seatbelt denials never reach app logs. `log` refuses to run inside the sandbox.
seatbelt() {
  local out
  if out=$(log show --last "${days}d" --style compact --predicate 'eventMessage CONTAINS "deny("' 2>&1); then
    printf '%s\n' "$out" | grep -E 'deny\(' || true
  else
    echo "UNREADABLE: macOS unified log ($out)" >&2
  fi
}

{
  # The agent's own shell commands are logged too ("spawning process"), and would match their own
  # grep patterns.
  [ -s "$files" ] && xargs grep -hE "$signature" <"$files" 2>/dev/null | grep -v 'spawning process'
  seatbelt
} | SIG=$signature awk '
  {
    date = "-"
    if (match($0, /timestamp"?[=:]"?[0-9]{4}-[0-9]{2}-[0-9]{2}/)) date = substr($0, RSTART + RLENGTH - 10, 10)
    line = $0
    # Long JSONL lines: keep only the neighbourhood of the match.
    if (length(line) > 400 && match(line, ENVIRON["SIG"])) {
      from = RSTART > 160 ? RSTART - 160 : 1
      line = substr(line, from, 160 + RLENGTH + 200)
    }
    gsub(/timestamp=[^ ]+ /, "", line)
    gsub(/run=[0-9a-f]+ /, "", line)
    gsub(/http\.span=[0-9]+ /, "", line)
    gsub(/[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.]+Z?/, "T", line)
    gsub(/\([0-9]+\)/, "(N)", line)
    gsub(/[0-9a-f]{8,}(-[0-9a-f]{4,})*/, "H", line)
    gsub(/nono-tool-sandbox-[^\/]*/, "nono-tool-sandbox-X", line)
    gsub(/[ \t]+/, " ", line)
    line = substr(line, 1, 400)
    n[line]++
    if (!(line in first) || date < first[line]) first[line] = date
    if (date > last[line]) last[line] = date
  }
  END { for (l in n) printf "%7d  %s  %s  %s\n", n[l], first[l], last[l], l }
' | sort -rn | head -n "$top"
