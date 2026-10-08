# Feature workflow

How to implement a feature with the orchestrator, the specialist agents, the nono sandbox and workmux.

Agents: `orchestrator` (default), `architect`, `dev`, `qa`, `security`, plus the built-in `explore`.
Definitions: `agents.nix` and `agents/*.md`. Sandbox and git guard: `sandbox.nix`.

## Before starting

- Create the feature branch yourself. The sandbox refuses `git switch -c` and `git checkout -b`, and git can only update the branch the session started on.
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

- Only `dev` edits project files. Each `dev` call asks for your approval (the main checkout does not get `--auto`).
- `qa` then runs the checks.
- `security` runs in parallel with `qa` when the change touches auth, secrets, untrusted input parsing, network exposure, process or file execution, crypto, dependencies, or CI and infra.
- At most two `dev` and `qa` rounds, then the orchestrator reports the state to you.

## 2b. New worktree (isolated)

1. The orchestrator writes the plan to `~/.opencode/plan/<file>.md`, where `<file>` is the branch name with `/` replaced by `-`. This is the only file it may write.
2. It prints `workmux add <branch> -P ~/.opencode/plan/<file>.md`.
3. You run that command from an unsandboxed pane. workmux cannot run inside the sandbox.
4. workmux opens a new tab and worktree with a sandboxed opencode. The wrapper detects the linked worktree and passes `--auto`.
5. The plan arrives as the first message. The orchestrator skips planning and runs `dev`, then `qa` (plus `security` when needed), without prompts.
6. Explicit denies still apply, and git can only move that worktree's branch.

## 3. Commit and ship

- Ask the orchestrator to commit. It runs `git add` and `git commit`. Each commit prompts you in the terminal and is signed as you.
- Review the diff yourself.
- From an unsandboxed pane, run `workmux merge --squash` or open a PR, then push.
- `git push`, merges and `npm publish` are denied for the agent.

## GitLab (read-only)

The agent can read MRs, issues and pipelines with `glab`, through a broker that never puts the token in the session.

- The token is `gitlab.agent_token` in the sops file, a personal token with only the `read_api` scope.
- Allowed: `glab mr view|list|diff|issues|approvers`, `issue view|list`, `ci status|list|view|get|trace`, `release view|list`, and `glab api <endpoint>` with GET only.
- Note: `repo view` currently returns 404 through the broker, so use `glab api`.
- Not allowed: anything that writes, `--web`, `--hostname`, `graphql`, combined short flags such as `-XPOST`, and a `-R` or URL that names another host.
- `glab` has no git access in the sandbox, so always pass `-R group/project`.
- The GitLab host is added to the sandbox's network allowlist at launch, so the agent can also reach it without a token. Other hosts stay blocked.
- Every `glab` call asks first, because unsandboxed OpenCode would run the real `glab` with your own token.
- Residual risk: the session can point `HTTPS_PROXY` at its own listener. The token stays inside the TLS stream, so it only sees the host name.

## What the sandbox enforces

- Writes only in the project folder, the plan folder and a few state folders.
- Git writes go through a broker that refuses ref updates outside the session's own branch, global options such as `--git-dir`, and writes to `.git/hooks` and `.git/config`.
- The orchestrator's `worktree`, `merge`, `coordinator` and `open-pr` skills are denied, because they need workmux or `gh`.

## Known gaps

- Not verified: how `workmux add -P` delivers the prompt to `opencode`. Test `workmux add test -p "hello"` once.
- Not verified: the commit approval prompt and the interactive TUI.
- The plan gate is a prompt rule, not a hard lock.
- A nested repo planted in a subfolder can escape the git guard, which protects only the project's own `.git`.
- Open decision: commits go through the orchestrator. The alternative is to commit through `dev`.
