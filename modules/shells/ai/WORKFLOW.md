# Feature workflow

How to implement a feature with the orchestrator, the specialist agents, the nono sandbox and workmux.

Agents: `orchestrator` (default), `architect`, `dev`, `qa`, `security`, plus the built-in `explore`.
Definitions: `agents.nix` and `agents/*.md`. Sandbox and git guard: `sandbox/` (`sandbox/git-broker.nix`).

## Before starting

- Create the feature branch yourself. The sandbox allows `git switch -c` and `git checkout -b`, and the git broker does not restrict which branch it updates.
- Run `opencode` in the project. This is the sandboxed wrapper. `opencode-unsandboxed` skips the sandbox.

## 1. Plan (no edits)

1. Describe the feature.
2. The orchestrator reads the code (`explore` for anything broad) and classifies the request as simple or complex.
3. Complex:
   - It asks a few focused questions with the question tool, each with a recommended option.
   - It asks "Want the plan?" (Yes). Typed text adds questions.
   - It briefs `architect` and presents that plan.
4. Simple: it skips the questions and writes a short plan itself.
5. A plan states the goal, the steps and files, how it will be verified, and the risks.
6. It asks **Implement here / New worktree / Cancel**. Typed text revises the plan, and the revised plan is presented again. It never calls `dev` before you choose one of the first two.

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

Claude Code runs in the same nono sandbox (`sandbox/claude-code.nix`; the shared profile skeleton is in `sandbox/default.nix`).

- `claude` is the sandboxed alias; `claude-unsandboxed` skips the sandbox. It uses the pinned dir `$XDG_STATE_HOME/claude-code`, which Home Manager exports as `CLAUDE_CONFIG_DIR` in every shell (`programs.claude-code.configDir`). There is no override. Aliases only exist in interactive shells, so scripts cannot reach the sandboxed entry point.
- Auth comes from the sops secret `ai/claude_api_key`, injected as `CLAUDE_CODE_OAUTH_TOKEN`. Create it with `claude setup-token` and add the key to `secrets/users/aaccardo.yaml` with sops.
- Config is isolated in `$XDG_STATE_HOME/claude-code-sandbox` (`CLAUDE_CONFIG_DIR` inside the sandbox), a writable dir separate from the pinned `$XDG_STATE_HOME/claude-code`. The sandbox has no grant on the pinned dir. A plain `claude` outside the alias (scripts, IDE) uses the pinned dir with its strict settings; nothing outside the sandbox dir bypasses prompts.
- Sandboxed sessions cannot write `.claude/` or `.mcp.json` anywhere in a project, or any `.claude` path (Seatbelt deny in the shared profile, `unsafe_macos_seatbelt_rules`; the OpenCode profile has it too). Reads still work. So a planted project hook or MCP server cannot run later in `claude-unsandboxed`.
- The sandbox dir's `settings.json` is the pinned one plus `permissions.defaultMode: bypassPermissions`, so bypass applies only to the sandboxed claude. `CLAUDE.md` and the generated MCP plugin (`hm`) are the same files as the pinned dir, linked from the store.
- The write-tool deny list for the Atlassian MCP lives in that `settings.json`. Home Manager restores a replaced link at the next switch (`backupFileExtension = "hm.old"`; activation can fail if a `.hm.old` file already exists). Files the session adds (plugins, skills, `.claude.json` mcpServers) are never removed.
- Residual: inside the sandbox dir the session can replace its own `settings.json` (dropping the deny list for later sandboxed runs) or add its own MCP plugin. Treat the Atlassian and OpenViking denies there as guards against mistakes, not as a boundary. Hardening (write grants limited to subdirs) is a follow-up.
- Only the binary is sandboxed: the orchestrator, specialist agents and commands stay OpenCode-only.
- Residual risk: the session holds `CLAUDE_CODE_OAUTH_TOKEN` (and the shared GitLab `read_api` token) in its environment, visible to every child process. It is a long-lived token; rotate it if leaked.

## OpenViking (read + remember)

OpenViking is a context database (`viking://` URIs) served as a remote MCP, `openviking.nix`. Both OpenCode and Claude Code get it, inside and outside the sandbox.

- The key is `ai/openviking_api_key` in the sops file. It never reaches the Nix store or a generated config as a literal.
- One header everywhere: `Bearer {env:OPENVIKING_API_KEY}` in OpenCode (sandboxed and global config) and `${OPENVIKING_API_KEY}` in Claude Code. The key lives only in the environment.
- Sandboxed: `OPENVIKING_API_KEY` comes from the profile's `set_vars` (`programs.nono.env`, shared by both profiles).
- Unsandboxed: `home.sessionVariables` sets it to `$(cat <sops path>)`, evaluated at login. After the first switch, log in again. A shared OpenCode background service started earlier, or outside a login shell, keeps the old environment, so run `opencode service restart`. The key is then in the environment of every unsandboxed process of the login session.
- Allowed domain: `openviking.protontech.ch`. Nothing else is opened.
- Prompts: in OpenCode every `openviking_*` call asks, in the sandbox too. `remember` is not denied; the agent instructions say to call it only when you ask. Sandboxed Claude does not prompt for `remember` (`bypassPermissions`).
- Name-based deny rules: `write`, `edit`, `add_resource`, `add_skill`, `forget`, `set_acl`, `cancel_watch`, plus the prefixes `add`, `set`, `write`, `edit`, `cancel`, `forget`, `delete`, `remove`, `create`, `update`, `upload`, `manage`, `grant`, `revoke`. The prefixes are a safety net for new tools. Read tools and `remember` match none of them.
- These denies are name-based guards, not a hard guarantee. Inside the sandbox the session holds the full API key (`OPENVIKING_API_KEY`) and shell is allowed, so a prompt-injected agent could call the server directly with `curl` and bypass them. Real enforcement needs a server-side key scoped to read + remember.
- Unsandboxed Claude (`claude-unsandboxed`, pinned dir `$XDG_STATE_HOME/claude-code`) loads the same OpenViking MCP plugin (`hm`) and the same deny list, from the pinned `settings.json`.
- Residual risks:
  - The session can read `OPENVIKING_API_KEY` from its environment.
  - `remember` can store untrusted content that later sessions read.
  - Sandboxed Claude Code runs with `bypassPermissions`, so its reads are not prompted; only the deny list applies.
  - The URL `/mcp` is assumed, not checked against the server.
  - Not verified yet: whether OpenCode v2 expands `{env:...}` in MCP headers.

## Figma (design files)

Figma's official remote MCP is in `figma.nix`, shared through `programs.mcp` by OpenCode and Claude Code.

- Auth is OAuth in the browser on first use. No token is stored in the config.
- Unsandboxed OpenCode asks for every `figma_*` call. The sandbox allows them, as it does shell and edit (`programs.nono.relaxedActions`, applied in `sandbox/opencode.nix`). Sandboxed Claude runs with `bypassPermissions`; unsandboxed Claude keeps its default prompts.
- Allowed domains: `mcp.figma.com`, `www.figma.com`, `api.figma.com`. Not verified: Figma's OAuth metadata could not be fetched, so the authorization and token hosts are a guess.
- Not verified in the sandbox: the OAuth callback port (OpenCode has `open_port_range`, the Claude profile has none) and token storage (the Keychain is denied).
- Accepted risks:
  - Sandboxed agents can write to Figma without a prompt. A prompt-injected agent could write data it can read into a Figma file or comment. This is an exfiltration path the user accepted; the instructions say never to do it.
  - The MCP OAuth token probably sits in a directory the session can read (the OpenCode data dir, the sandboxed Claude config dir). Not verified.
  - The `figma_*` allow applies to every agent, read-only ones and the orchestrator included.
  - The shared allow-domain list also applies to the Claude profile. The three hosts are a guess to tighten after the first real login.
  - A project-level `opencode.json` in the repo root is loaded only by unsandboxed OpenCode.

## What the sandbox enforces

- Unsandboxed OpenCode uses the strict global rules. Sandboxed OpenCode loads a generated config through `OPENCODE_CONFIG_DIR`: the same config, where the asks of `programs.nono.relaxedActions` (shell, edit, figma_*; see `sandbox/opencode.nix`) become allow, so nono is the boundary. The other asks stay: the `subagent dev` gate and the atlassian and slack MCP asks. Deny rules and the `experimental.policies` hard denies are unchanged in both modes. The Claude Code alias runs with `bypassPermissions` from its sandbox config dir for the same reason. Do not set `session.permissions: autoaccept` in `cli.json`: it bypasses the `dev` gate.
- Writes only in the project folder, the plan folder and a few state folders.
- Git writes go through a broker that refuses global options such as `--git-dir` and writes to `.git/hooks` and `.git/config`. It does not restrict ref updates.
- The orchestrator's `worktree`, `merge`, `coordinator` and `open-pr` skills are denied, because they need workmux or `gh`.

## Known gaps

- Not verified: how `workmux add -P` delivers the prompt to `opencode`. Test `workmux add test -p "hello"` once.
- Not verified: the interactive TUI.
- The plan gate is a prompt rule, not a hard lock.
- A nested repo planted in a subfolder can escape the git guard, which protects only the project's own `.git`.
- Open decision: commits go through the orchestrator. The alternative is to commit through `dev`.
