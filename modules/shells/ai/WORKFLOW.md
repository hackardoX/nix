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

1. The orchestrator runs `workmux add <branch> --headless --json`. The worktree goes under `<project>/.worktrees/<handle>`.
2. It writes the plan to `~/.opencode/plan/<file>.md`, where `<file>` is the branch name with `/` replaced by `-`. This is the only file it may write.
3. It prints `workmux open <handle>` and the plan path. Headless add rejects `-P`, so the plan is not injected.
4. You run `workmux open <handle>` from an unsandboxed pane. That opens the tab with a sandboxed opencode.
5. In that session you say to implement the plan at that path. The session then runs `dev`, then `qa` (plus `security` when needed). Each `dev` call still asks.
6. Explicit denies still apply. Git writes go through the broker, which does not restrict which refs a worktree's branch can move.

## 3. Commit and ship

- Ask the orchestrator to commit. It runs `git add` and `git commit`. Commits inside the sandbox are not prompted; they are signed as you, so only ask for a commit when you want one.
- Review the diff yourself.
- From an unsandboxed pane, run `workmux merge --squash` or open a PR, then push.
- `git push`, merges and `npm publish` are denied for the agent.

## GitLab (read-only via MCP)

GitLab's official remote MCP server is in `gitlab.nix`, shared through `programs.mcp` by OpenCode and Claude Code.

- Auth is OAuth in the browser on first use (`opencode mcp auth gitlab`). No token is stored in the config.
- Needs GitLab 18.6+, with MCP access enabled by an admin. Dynamic client registration is rate limited to 10 per hour per IP.
- The toolsets header only works on GitLab 19.5+. Older servers may reject it or ignore it; an unknown toolset name returns 400. Most write-tool names date from 19.3-19.4; older versions are covered by the aliases and prefixes.
- The host comes from `GITLAB_HOST`, never a literal in the repo or store. Sandboxed: `programs.nono.env`. Unsandboxed: `forges/gitlab.nix` sets it as a session variable, so run `opencode service restart` after the first switch.
- Only the GitLab host is allowed in the sandbox. The OAuth flow runs against the same host, so nothing else is opened.
- The toolsets header (`core,merge_requests,work_items,repository,ci`) omits Duo Agent Platform.
- In OpenCode every `gitlab_*` call asks, in the sandbox too. Sandboxed Claude runs with `bypassPermissions`, so only the deny list applies.
- Write tools are denied by name and by prefix (`add`, `create`, `update`, `save`, `merge`, ...). Read tools match none of the prefixes.
- Residual risks:
  - Writes no longer fail on the server. The OAuth token (scope `mcp`) carries your full role, unlike the former `read_api` token. Read-only rests on the name-based denies alone.
  - OpenCode: the sandboxed session can read the stored MCP OAuth token (read-write grant on `$XDG_DATA_HOME/opencode`, `sandbox/opencode.nix`). Shell is auto-allowed in the sandbox and the GitLab host is reachable, so a prompt-injected agent could POST a `tools/call` to `https://$GITLAB_HOST/api/v4/mcp` (e.g. `accept_merge_request`, `add_commit`, `save_pipeline`), bypassing the name-based denies and prompts.
  - Claude: the token is probably in the Keychain (not verified).
  - The `mcp` scope token works on `/api/v4/mcp` only, not the general REST API.
  - The denies are guards, not a boundary.
- Mitigation, not implemented: a separate Reporter/Guest-only GitLab account, or a fine-grained PAT with MCP Execute plus read-only resource permissions, passed in a header from an env var whose name does not end in `_TOKEN`.
- Cleanup: revoke the old `read_api` personal access token in GitLab and remove `gitlab.agent_token` from the sops file.
- Sandboxed `glab` (still installed via `tuicr.nix`) no longer has `GLAB_CONFIG_DIR` pointed at an empty dir, so it may read your own glab config if one exists (not verified).
- NOT VERIFIED:
  - That OpenCode expands `{env:GITLAB_HOST}` in the `url` field.
  - That the instance runs a version exposing these tool names. The list is taken from GitLab's master docs.

## Claude Code

Claude Code runs in the same nono sandbox (`sandbox/claude-code.nix`; the shared profile skeleton is in `sandbox/default.nix`).

- `claude` is the sandboxed alias; `claude-unsandboxed` skips the sandbox. It uses the pinned dir `$XDG_STATE_HOME/claude-code`, which Home Manager exports as `CLAUDE_CONFIG_DIR` in every shell (`programs.claude-code.configDir`). There is no override. Aliases only exist in interactive shells, so scripts cannot reach the sandboxed entry point.
- Auth comes from the sops secret `ai/claude_api_key`, injected as `CLAUDE_CODE_OAUTH_TOKEN`. Create it with `claude setup-token` and add the key to `secrets/users/aaccardo.yaml` with sops.
- Config is isolated in `$XDG_STATE_HOME/claude-code-sandbox` (`CLAUDE_CONFIG_DIR` inside the sandbox), a writable dir separate from the pinned `$XDG_STATE_HOME/claude-code`. The sandbox has no grant on the pinned dir. A plain `claude` outside the alias (scripts, IDE) uses the pinned dir with its strict settings; nothing outside the sandbox dir bypasses prompts.
- Sandboxed sessions cannot write `.claude/` or `.mcp.json` anywhere in a project, or any `.claude` path (Seatbelt deny in the shared profile, `unsafe_macos_seatbelt_rules`; the OpenCode profile has it too). Reads still work. So a planted project hook or MCP server cannot run later in `claude-unsandboxed`.
- The sandbox dir's `settings.json` is the pinned one plus `permissions.defaultMode: bypassPermissions`, so bypass applies only to the sandboxed claude. `CLAUDE.md` and the generated MCP plugin (`hm`) are the same files as the pinned dir, linked from the store.
- The write-tool deny list for the Atlassian and GitLab MCPs lives in that `settings.json`. Home Manager restores a replaced link at the next switch (`backupFileExtension = "hm.old"`; activation can fail if a `.hm.old` file already exists). Files the session adds (plugins, skills, `.claude.json` mcpServers) are never removed.
- Residual: inside the sandbox dir the session can replace its own `settings.json` (dropping the deny list for later sandboxed runs) or add its own MCP plugin. Treat the Atlassian, GitLab and OpenViking denies there as guards against mistakes, not as a boundary. Hardening (write grants limited to subdirs) is a follow-up.
- Only the binary is sandboxed: the orchestrator and specialist agents stay OpenCode-only.
- Residual risk: the session holds `CLAUDE_CODE_OAUTH_TOKEN` in its environment, visible to every child process. It is a long-lived token; rotate it if leaked.

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

- Unsandboxed OpenCode uses the strict global rules. Sandboxed OpenCode loads a generated config through `OPENCODE_CONFIG_DIR`: the same config, where the asks of `programs.nono.relaxedActions` (shell, edit, figma_*; see `sandbox/opencode.nix`) become allow, so nono is the boundary. The other asks stay: the `subagent dev` gate and the atlassian, gitlab and slack MCP asks. Deny rules and the `experimental.policies` hard denies are unchanged in both modes. The Claude Code alias runs with `bypassPermissions` from its sandbox config dir for the same reason. Do not set `session.permissions: autoaccept` in `cli.json`: it bypasses the `dev` gate.
- Writes only in the project folder (including `.worktrees/`), the plan folder and a few state folders.
- The session has no zellij socket on purpose: it would let the session type into unsandboxed panes. Windowed workmux commands (`open`, windowed `add`, `dashboard`, `sidebar`) therefore fail closed.
- Git writes go through a broker that refuses global options such as `--git-dir` and writes to `.git/hooks` and `.git/config`. It does not restrict ref updates.
- The orchestrator's `worktree`, `merge` and `coordinator` skills open multiplexer windows, and `open-pr` needs `gh`. All four are denied. The orchestrator calls the `workmux` CLI directly.

## Known gaps

- Not verified: `git worktree` under the broker, whether workmux stores metadata via `git config` (denied by the broker), and `workmux merge`/`remove` behaviour without a multiplexer.
- Not verified: whether workmux expands or accepts a relative `worktree_dir` (`.worktrees`), and whether the starship prompt runs git in a worktree the session wrote.
- Not verified: hard links to protected files bypass the path rules.
- Git broker writes (`git apply`, `checkout -- <file>`, `am`, `cherry-pick`, `worktree add` of a branch) run in the broker's sandbox and can still create `.claude/`, `.mcp.json`, `.workmux.yaml` or `.workmux.yml` in the tree. Review diffs and look for these files before running `workmux open` or `merge` unsandboxed. Accepted: not denied in the broker, because git would fail midway on repos that track these files.
- workmux finds project config by walking up the tree (`.workmux.yaml` and `.workmux.yml`). The Seatbelt rule is a speed bump, not a boundary.
- Not verified: the interactive TUI.
- The plan gate is a prompt rule, not a hard lock.
- A nested repo planted in a subfolder can escape the git guard, which protects only the project's own `.git`.
- Open decision: commits go through the orchestrator. The alternative is to commit through `dev`.
