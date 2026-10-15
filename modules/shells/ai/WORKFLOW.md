# Feature workflow

How to implement a feature with the orchestrator, the specialist agents, the nono sandbox and workmux.

Agents: `orchestrator` (default), `architect`, `dev`, `qa`, `security`, plus the built-in `explore`.
Definitions: `agents.nix` and `agents/*.md`. Sandbox and git guard: `sandbox.nix`.

## Before starting

- Create the feature branch yourself. The sandbox allows `git switch -c` and `git checkout -b`, and the git broker does not restrict which branch it updates.
- Run `opencode` in the project. This is the sandboxed wrapper. `opencode-unsandboxed` skips the sandbox.

## 1. Plan (no edits)

1. Describe the feature.
2. The orchestrator reads the code (`explore` for anything broad) and classifies the request as simple or complex.
3. Complex:
   - It asks a few focused questions with the question tool, each with a recommended option.
   - It asks "Want the plan?" (Yes / More questions).
   - It briefs `architect` and presents that plan.
4. Simple: it skips the questions and writes a short plan itself.
5. A plan states the goal, the steps and files, how it will be verified, and the risks.
6. It asks **Implement here / New worktree / Revise / Cancel**. It never calls `dev` before you choose one of the first two.

## 2a. Implement here

- Only `dev` edits project files. Each `dev` call asks for your approval, here and in a worktree (the sandbox config does not relax the `subagent dev` gate).
- `qa` then runs the checks.
- `security` runs in parallel with `qa` when the change touches auth, secrets, untrusted input parsing, network exposure, process or file execution, crypto, dependencies, or CI and infra.
- At most two `dev` and `qa` rounds, then the orchestrator reports the state to you.

## 2b. New worktree (isolated)

1. The orchestrator writes the plan to `~/.opencode/plan/<file>.md`, where `<file>` is the branch name with `/` replaced by `-`. This is the only file it may write.
2. It prints `workmux add <branch> -P ~/.opencode/plan/<file>.md`.
3. You run that command from an unsandboxed pane. workmux cannot run inside the sandbox.
4. workmux opens a new tab and worktree with a sandboxed opencode.
5. The plan arrives as the first message. The orchestrator skips planning and runs `dev`, then `qa` (plus `security` when needed). Each `dev` call still asks.
6. Explicit denies still apply, and git can only move that worktree's branch.

## 3. Commit and ship

- Ask the orchestrator to commit. It runs `git add` and `git commit`. Commits inside the sandbox are not prompted; they are signed as you, so only ask for a commit when you want one.
- Review the diff yourself.
- From an unsandboxed pane, run `workmux merge --squash` or open a PR, then push.
- `git push`, merges and `npm publish` are denied for the agent.

## GitLab (read-only)

The agent can read MRs, issues and pipelines with `glab`, which runs inside the sandbox with a token in its environment. The wrapper injects it into the session through the generated sandbox profile (`set_vars`), not by exporting it; the sandbox denies every other `*_TOKEN`.

- The token is `gitlab.agent_token` in the sops file, a personal token with only the `read_api` scope. Writes fail anyway.
- The GitLab host is added to the sandbox's network allowlist at launch, so the proxy only lets `glab` (and the session) reach that one host. Other hosts stay blocked.
- `glab` has no git access in the sandbox, so always pass `-R group/project`.
- Every `glab` call asks first in unsandboxed OpenCode, because it would run the real `glab` with your own token. In the sandbox the generated config allows `glab` for the agents (read-only token).
- Residual risk: the session can read `GITLAB_TOKEN` and talk to the host directly, not just through `glab`. The token is read-only, and only that one host is reachable.

## Claude Code

Claude Code runs in the same nono sandbox (`sandbox.nix`, profile included there).

- `claude` is the sandboxed alias; `claude-unsandboxed` skips the sandbox and needs no config pin. Aliases only exist in interactive shells, so scripts cannot reach the sandboxed entry point.
- Auth comes from the sops secret `ai/claude_api_key`, injected as `CLAUDE_CODE_OAUTH_TOKEN`. Create it with `claude setup-token` and add the key to `secrets/users/aaccardo.yaml` with sops.
- Config is isolated in `$XDG_STATE_HOME/claude-code` (`CLAUDE_CONFIG_DIR`), so the session cannot plant settings or hooks the unsandboxed claude would run later. The global `CLAUDE_CONFIG_DIR` is forced back to `~/.claude`, so any claude started outside the alias (scripts, IDE) uses `~/.claude` and never the sandbox dir; the sandboxed alias is the only user of the isolated dir.
- MCP servers come from `programs.mcp`, delivered through HM's claude-code integration as a generated plugin (`hm`) inside the isolated config dir.
- The write-tool deny list for the Atlassian MCP lives in `settings.json` inside that writable config dir. Known limitation: the session could replace it; hardening (write grants limited to subdirs) is a follow-up.
- Only the binary is sandboxed: the orchestrator, specialist agents and commands stay OpenCode-only.
- Residual risk: the session holds `CLAUDE_CODE_OAUTH_TOKEN` (and the shared GitLab `read_api` token) in its environment, visible to every child process. It is a long-lived token; rotate it if leaked.

## What the sandbox enforces

- Unsandboxed OpenCode uses the strict global rules. Sandboxed OpenCode loads a generated config through `OPENCODE_CONFIG_DIR`: the same config, where the shell and edit asks become allow, so nono is the boundary. The other asks stay: the `subagent dev` gate and the atlassian and slack MCP asks. Deny rules and the `experimental.policies` hard denies are unchanged in both modes. The Claude Code alias uses `--permission-mode bypassPermissions` for the same reason. Do not set `session.permissions: autoaccept` in `cli.json`: it bypasses the `dev` gate.
- Writes only in the project folder, the plan folder and a few state folders.
- Git writes go through a broker that refuses global options such as `--git-dir` and writes to `.git/hooks` and `.git/config`. It does not restrict ref updates.
- The orchestrator's `worktree`, `merge`, `coordinator` and `open-pr` skills are denied, because they need workmux or `gh`.

## Known gaps

- Not verified: how `workmux add -P` delivers the prompt to `opencode`. Test `workmux add test -p "hello"` once.
- Not verified: the interactive TUI.
- The plan gate is a prompt rule, not a hard lock.
- A nested repo planted in a subfolder can escape the git guard, which protects only the project's own `.git`.
- Open decision: commits go through the orchestrator. The alternative is to commit through `dev`.
