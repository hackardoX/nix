# Rust + Bazel editor setup — changes needed

Context: this monorepo builds Rust with Bazel (rules_rust 0.73.0, patched fork).
Deps live in Bazel's `@crate_index`, not `~/.cargo`. Toolchain is pinned to
Rust 1.95.0 (`rust-toolchain.toml`, `MODULE.bazel`); rustfmt is pinned to
nightly-2025-08-20. Canonical docs: `doc/rust-analyzer.md` at repo root.

Constraint: none of these changes may add repo-specific config to the personal
nixvim/home-manager config. Everything below is repo-local (checkout-scoped)
or expressed as a generic rule in nix config.

## 1. Run the Bazel rust-analyzer setup (required)

- Run from monorepo root:
  `bazel run @rules_rust//tools/rust_analyzer:setup -- neovim`
- Why: generates the launcher binaries + `discover_bazel_roots` command so
  rust-analyzer resolves deps from Bazel instead of `cargo metadata`.
- Re-run after any toolchain / MODULE.bazel change or `bazel clean --expunge`.
- macOS: each launcher needs "Open Anyway" in Privacy & Security on first run.

## 2. Wire rust-analyzer via repo-local config, not nix config (required)

- The `workspace.discoverConfig` + `procMacro.enable` settings (see rules_rust
  neovim docs linked from `doc/rust-analyzer.md`) must come from a project-
  scoped source, e.g. an exrc/local nvim config detected when editing inside
  a checkout that contains `.bazelversion` + root `Cargo.toml`.
- Why: keeps personal nix config free of this repo's paths/targets; the
  discover settings are meaningless outside Bazel-managed Rust repos.
- Generalized alternative allowed in nix config: a single generic rule such as
  "enable discoverConfig when a repo-local marker indicates Bazel rust setup"
  — no repo names, paths, or versions in nix.

## 3. Match rust-analyzer to the pinned toolchain (required)

- Current nix config uses nixpkgs rust-analyzer (`packageFallback = true`),
  whose version drifts from the repo's pinned 1.95.0 → false type errors.
- Fix: point the LSP at the Bazel-generated rust-analyzer launcher (from
  step 1, resolved relative to the checkout) instead of nixpkgs'.
- Why: RA and rustc must agree on version; the launcher is the only copy
  guaranteed to match the repo. Generic-safe: the launcher path is discovered
  per-checkout, not hardcoded in nix.

## 4. Wrapper script if a global cargo is on PATH (conditional)

- Applies when nix cargo/rustc are on PATH (they are). RA runs an internal
  `cargo metadata` for sysroot enrichment and must find a cargo matching its
  own toolchain, not nix's.
- Fix: wrapper script (template in `doc/rust-analyzer.md` §Helix known issues)
  that prepends the Bazel-vendored toolchain bin dir and sets
  `RUSTC_BOOTSTRAP=1`, then execs the launcher. Store it repo-local.
- Skip only if step 3's launcher already resolves the right cargo.

## 5. Diagnostics: keep clippy opt-in (recommended)

- `check.command = "clippy"` runs `cargo clippy` on the whole workspace: slow,
  requires the artifact-keeper mirror, uses nix clippy (not the pinned one),
  and misjudges Bazel-only quirks (patched crates, per-platform features).
- Options: keep cargo clippy for live diagnostics but expect noise, or disable
  RA diagnostics in-repo and rely on `bazel build --config=clippy //...`.
- Decision needed: which tradeoff (live-but-noisy vs authoritative-but-manual).

## 6. Formatting: align rustfmt with the pinned nightly (recommended)

- Repo pins rustfmt nightly-2025-08-20; nix stable rustfmt silently ignores
  unstable options in `rustfmt.toml` → CI (`bazel run //:format`) reformats
  local changes.
- Fix: in-repo override making rustfmt resolve to the Bazel toolchain's
  rustfmt (via RA's `rustfmt` setting or a repo-local conform formatter),
  again without touching nix config.

## 7. Working habits (no config)

- Open the monorepo root, not subfolders (otherwise RA picks a non-root
  Cargo.toml; discoverConfig handles this once steps 1–3 are done).
- `rust-project.json` as an opencode rootMarker is fine to keep.

## Done criteria

- RA resolves external crates + build-script output in `project/calendar/rust`.
- Hover/goto works inside third-party crate sources.
- `bazel run //:format` produces no diffs after saving through the editor.
- Personal nix config contains no proton/monorepo/calendar-specific strings.
