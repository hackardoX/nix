---
name: diagnosing-nono-sandbox
description: Use when a sandboxed agent harness (OpenCode, Claude Code or any programs.nono.harnesses entry) shows EPERM, "Operation not permitted", "command policy denied" or proxy refusals in its logs, or when asked to audit a harness's logs for nono misconfiguration and fix the flake's sandbox modules.
---

# Diagnosing nono sandbox denials

Logs show symptoms; `nono why` against the harness's exported profile is the oracle. Most denials are deliberate policy. Only a missing grant for legitimate work is a misconfiguration.

## Steps

1. **Harness.** Use the argument if given. Without one, run `bash scripts/scan-denials.sh --list` and handle every listed harness.
2. **Scan.** `bash scripts/scan-denials.sh [--days N] <harness> [extra log paths]` prints one line per distinct signature: count, first seen, last seen (counts include retries: read them as frequency). Lines starting `UNREADABLE` or `MISSING` are evidence gaps. Report them and never conclude "no errors" from them. A sandboxed session cannot read other harnesses' state dirs or the macOS unified log (Seatbelt denials): ask the user to rerun from `opencode-unsandboxed` or a plain terminal, or to pass a log path.
3. **Verify each path, command or host signature.**
   `nono-profile-<harness> > $TMPDIR/<harness>.json`, then
   `nono why --profile $TMPDIR/<harness>.json --path <P> --op read|write|readwrite --json`
   (or `--command git --caller session -- <argv>`, or `--host <H>`). Check the exit status before piping to `jq`. For `command policy denied`, the blocked argv is the nearest `spawning process` line before it in the log. If `why` fails with `Failed to canonicalize path` on a path the sandbox hides, drop that entry from the JSON copy and ignore results beneath it.
4. **Classify** by the `reason` that `nono why` returns:

| Result                                            | Class                                      | Action                                                                                                                             |
| ------------------------------------------------- | ------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| `insufficient_access`, `path_not_granted`         | Misconfiguration if the work is legitimate | Propose a grant                                                                                                                    |
| `filesystem_deny`                                 | Deliberate                                 | Report only                                                                                                                        |
| command-policy denial (`command policy denied`)   | Deliberate broker policy                   | Fix the caller, not the policy                                                                                                     |
| `granted_path` yet still EPERM                    | A raw rule `why` cannot see                | Check `unsafe_macos_seatbelt_rules` in `sandbox/default.nix`, and the brokered command's own `sandbox` in `sandbox/git-broker.nix` |
| Proxy 403 or host denied                          | Network allowlist                          | `nono why --host`, then `allow_domain`                                                                                             |
| 502 DNS, ENOTFOUND, timeout, ENOENT, expired auth | Not nono                                   | List separately                                                                                                                    |

5. **Propose the fix** in the flake module that owns it:
   - Harness-only grants: `sandbox/<harness>.nix` (`allow` read+write dir, `read` read-only dir, `allowFile` one file, `extra` profile sections).
   - Grants every harness needs: the skeleton in `sandbox/default.nix`.
   - Brokered commands (git, ssh): `commands.<name>.from.<caller>.sandbox` in `sandbox/git-broker.nix`.
   - Option shapes: `sandbox/meta.nix`.

   Pick the first that applies:
   1. Turn off or redirect the feature that triggers the denial, in the harness config: OpenCode `sandboxSettings` in `sandbox/opencode.nix` (sandbox only; `programs.opencode.settings` in `ai/opencode.nix` also hits unsandboxed runs), Claude Code `settings.json` in `sandbox/claude-code.nix`. Check the key name against the installed version (`opencode2 --version`, then its docs); it differs between releases. Confirm by the signature disappearing from the next log.
   2. Grant the narrowest directory the tool owns (`suggested_flag` is only the single failing path: a cache needs its whole dir), read+write only when the log shows a write.
   3. Removing a deny or broker rule is a user decision: state what it re-opens and do not make it the default.

6. **Re-verify.** Apply the grant to the JSON copy, e.g. `jq '.filesystem.allow += ["$HOME/.npm/_cacache"]'` (single quotes: nono expands `$HOME`), and rerun `nono why`. Expect `allowed`. A config-key change cannot be verified this way.
7. **Report.** A table (signature, count, first to last seen, `why` reason, class, diff), then "Not nono" and "Evidence gaps". Last seen before the latest change under the sandbox module (`git log -1 --format=%cI -- modules/shells/ai/sandbox`) means likely already fixed. Propose diffs; edit the flake only when asked.

## New harness

Add a case to `scripts/scan-denials.sh` with its log locations. Find them from the harness's `env` in its `sandbox/<harness>.nix` (config dir variables).
