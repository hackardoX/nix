# Feature workflow

How to implement a feature with the orchestrator, the specialist agents, the nono sandbox and workmux.

Agents: `orchestrator` (default), `architect`, `dev`, `qa`, `security`, plus the built-in `explore`.
Definitions: `agents.nix` and `agents/*.md`. Sandbox and git guard: `sandbox/` (`sandbox/git-broker.nix`).

## Before starting

- Create the feature branch yourself. The sandbox allows `git switch -c` and `git checkout -b`, and the git broker does not restrict which branch it updates.
- Run `opencode` in the project. This is the sandboxed wrapper. `opencode-unsandboxed` skips the sandbox.

## 1. Plan (no edits)

The orchestrator does not edit project files by instruction, but its shell is not read-only (see 2a). Only the prompt rule stops it, not a permission.

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

- Only `dev` edits project files, by instruction. This is a prompt rule for the orchestrator, not a permission: its shell is not read-only, so a shell command could still write files. Each `dev` call asks for your approval, here and in a worktree (the sandbox config does not relax the `subagent dev` gate).
- Shell for the orchestrator: outside the sandbox every command asks, except the global allow list (`ls`, `cat`, `grep`, `git status`, `git diff`, `git log`, `git show`, `git blame`, `git ls-files`, `git rev-parse`, `git branch --show-current`, `git add`) and `git commit`, which the agent rules allow. Inside the sandbox, shell asks are relaxed to allow and nono is the boundary. The hard denies (`git push`, `gh pr merge`, `npm publish`) still apply in both modes.
- `qa` then runs the checks.
- `security` runs in parallel with `qa` when the change touches auth, secrets, untrusted input parsing, network exposure, process or file execution, crypto, dependencies, or CI and infra.
- At most two `dev` and `qa` rounds, then the orchestrator reports the state to you.

## 2b. New worktree (isolated)

1. The orchestrator writes the plan to `~/.local/state/opencode/plan/<file>.md`, where `<file>` is the branch name with `/` replaced by `-`. This is the only file it may write.
2. It runs `workmux add <branch> -b -P ~/.local/state/opencode/plan/<file>.md`. nono asks you to approve the call. The new tab holds a sandboxed opencode, and the worktree goes under `~/.local/state/workmux/worktrees/<project>`.
3. If the call fails, or the session is not sandboxed, run the same command yourself in an unsandboxed pane. `--headless` is not used: workmux rejects prompt options with it.
4. The new session implements the plan. If the plan is not injected, tell it to implement the plan at that path. It runs `dev`, then `qa` (plus `security` when needed). Each `dev` call still asks.
5. Explicit denies still apply. Git writes go through the broker, which does not restrict which refs a worktree's branch can move.

Panes run the sandboxed agent through the named workmux agent `opencode-sandboxed` (nono wrapper), because shell aliases are not available in panes.

## 3. Commit and ship

- Ask the orchestrator to commit. It runs `git add` and `git commit`. Commits inside the sandbox are not prompted; they are signed as you, so only ask for a commit when you want one.
- Review the diff yourself.
- From an unsandboxed pane, run `workmux merge --squash` or open a PR, then push.
- `git push`, merges and `npm publish` are denied for the agent.

## GitLab (glab through the nono broker)

Inside the sandbox, `glab` runs through a command edge of the broker (`gitlab.nix`, `commands.glab`). The GitLab token is kept out of the agent's environment and files; it is only in the environment of the glab child process the broker starts. That child gets `HOME` set to the glab state dir, so it does not inherit the session's `HOME`. Outside the sandbox (unsandboxed agents) glab uses your own token with no argv policy.

- Token: `gitlab/agent_api_token`, an api-scope personal access token. Create it in GitLab and add it to `secrets/users/aaccardo.yaml` with sops before switching. Host: `gitlab/host` (sops). The old `gitlab/agent_token` (read_api) is no longer used.
- Default deny, with an allowlist. Reads run without a prompt: `mr view|list|diff|issues|approvers`, `issue view|list`, `ci status|list|get|trace`, `repo view`, `release view|list`, and the exact `--version` and `version`.
- Writes ask in the terminal (the terminal approval backend, 120 s, from `git-broker.nix`): `mr create|update|note|approve`, `issue create|update|note`. `mr update` can set assignees and reviewers. The glab child has no tty, so it cannot prompt; `NO_PROMPT` keeps it from waiting.
- Denied: merge, delete, close, `glab api`, auth and config. `ci view` is not allowed (interactive TUI with run, retry and cancel keys).
- Limits:
  - Matching is literal argv. The subcommand must come first, so `glab -R x mr view` is denied, and `--flag=value` forms are not normalized.
  - The token has api scope, so this is a guard, not a boundary: an approved write runs with the full token.
  - merge and close are still reachable through GitLab quick actions in an approved note or description (a line starting with `/`). The user reads the body in the approval prompt.
- Security review findings (not fixed here):
  - The token sits in the glab child's environment. Same-user processes may be able to read it on macOS (`ps -E`). Not verified under nono's Seatbelt. Hardening option: a command-scoped nono `proxy` credential with an `endpoint_policy` (token never in the child env, HTTP-level allowlist). That needs glab pointed at the loopback proxy.
  - `-R` accepts a full URL, so a read could target another host if `network.allow_domain` is not enforced for the edge. Test after switching: `glab mr list -R https://example.com/a/b` must fail.
  - The `workmux` edge (`workmux.nix`, `invocation_policy.default = "allow"`, zellij socket, shell asks relaxed in the sandbox) may let the session run commands unsandboxed or send keystrokes to the approval prompt (`workmux run`, `send`, `add -a`; not verified in this fork). If true, it undermines both the token hiding and the approve prompts. Follow-up: restrict that edge.
  - The approve prompt renders attacker-controlled argv (multi-line, escape sequences). How nono renders it is not verified.
- Cleanup before switching: remove `gitlab.agent_token` from sops and revoke the old read_api token in GitLab. Remove any MCP OAuth token left under `$XDG_DATA_HOME/opencode` (`opencode mcp auth gitlab` for the old MCP).
- NOT VERIFIED:
  - That glab runs at all through the broker, and that Go TLS works in a macOS command sandbox.
  - That `network.allow_domain` on the glab edge restricts it to the GitLab host.
  - That glab reads and writes only `GLAB_CONFIG_DIR` (`opencode-glab`) and does not probe the keyring.
  - That `NO_PROMPT` stops every prompt.
  - That a direct exec of glab's store path from the session is denied. nono denies it by default because `allow_direct_exec_bypass` is not set, and `deny_direct_exec_bypass` is not set for glab (it conflicts with git-broker's list). The nono 0.80.0 binary has the message, not tested at runtime.

## Claude Code

Claude Code runs in the same nono sandbox (`sandbox/claude-code.nix`; the shared profile skeleton is in `sandbox/default.nix`).

- `claude` is the sandboxed alias; `claude-unsandboxed` skips the sandbox. It uses the pinned dir `$XDG_STATE_HOME/claude-code`, which Home Manager exports as `CLAUDE_CONFIG_DIR` in every shell (`programs.claude-code.configDir`). There is no override. Aliases only exist in interactive shells, so scripts cannot reach the sandboxed entry point.
- Auth comes from the sops secret `ai/claude_api_key`, injected as `CLAUDE_CODE_OAUTH_TOKEN`. Create it with `claude setup-token` and add the key to `secrets/users/aaccardo.yaml` with sops.
- Config is isolated in `$XDG_STATE_HOME/claude-code-sandbox` (`CLAUDE_CONFIG_DIR` inside the sandbox), a writable dir separate from the pinned `$XDG_STATE_HOME/claude-code`. The sandbox has no grant on the pinned dir. A plain `claude` outside the alias (scripts, IDE) uses the pinned dir with its strict settings; nothing outside the sandbox dir bypasses prompts.
- Sandboxed sessions cannot write `.claude/` or `.mcp.json` anywhere in a project, or any `.claude` path (Seatbelt deny in the shared profile, `unsafe_macos_seatbelt_rules`; the OpenCode profile has it too). Reads still work. So a planted project hook or MCP server cannot run later in `claude-unsandboxed`.
- The sandbox dir's `settings.json` is the pinned one plus `permissions.defaultMode: bypassPermissions`, so bypass applies only to the sandboxed claude. `CLAUDE.md` and the generated MCP plugin (`hm`) are the same files as the pinned dir, linked from the store.
- The write-tool deny list for the Atlassian MCP lives in that `settings.json`. Home Manager restores a replaced link at the next switch (`backupFileExtension = "hm.old"`; activation can fail if a `.hm.old` file already exists). Files the session adds (plugins, skills, `.claude.json` mcpServers) are never removed.
- Residual: inside the sandbox dir the session can replace its own `settings.json` (dropping the deny list for later sandboxed runs) or add its own MCP plugin. Treat the Atlassian and OpenViking denies there as guards against mistakes, not as a boundary. Hardening (write grants limited to subdirs) is a follow-up.
- Only the binary is sandboxed: the orchestrator and specialist agents stay OpenCode-only.
- Residual risk: the session holds `CLAUDE_CODE_OAUTH_TOKEN` in its environment, visible to every child process. It is a long-lived token; rotate it if leaked.

## OpenViking (read + remember)

OpenViking is a context database (`viking://` URIs), `openviking.nix`. Both OpenCode and Claude Code get it, inside and outside the sandbox.

- OpenCode uses the pinned npm plugin `@openviking/opencode-plugin@2026.10.26-2` (`plugins` in the OpenCode settings, the v2 key). The plugin registers a local stdio MCP named `openviking`, so tool names stay `openviking_*`. The pin is on purpose: bump it by hand after reading the changes.
- Claude Code still uses the remote MCP over Streamable HTTP, with `${OPENVIKING_API_KEY}` expanded by Claude itself.
- The key is `ai/openviking_api_key` in the sops file. It never reaches the Nix store or a generated config as a literal.
- Environment: `OPENVIKING_API_KEY` (secret) and `OPENVIKING_URL` (the base URL, not secret; the plugin and the Claude MCP append `/mcp`). The sandbox gets both from `programs.nono.env`, shared by both profiles. Unsandboxed, `home.sessionVariables` sets the key to `$(cat <sops path>)`, evaluated at login, and the URL as a plain value. After the first switch, log in again. A shared OpenCode background service started earlier, or outside a login shell, keeps the old environment, so run `opencode service restart`. The key is then in the environment of every unsandboxed process of the login session.
- Prompts: in OpenCode every `openviking_*` call asks outside the sandbox. Inside it the asks are relaxed to allow (`programs.nono.relaxedActions`). `remember` is not denied; the agent instructions say to call it only when you ask. Sandboxed Claude does not prompt for `remember` (`bypassPermissions`).
- Name-based deny rules: `write`, `edit`, `add_resource`, `add_skill`, `forget`, `set_acl`, `cancel_watch`, plus the prefixes `add`, `set`, `write`, `edit`, `cancel`, `forget`, `delete`, `remove`, `create`, `update`, `upload`, `manage`, `grant`, `revoke`. The list covers every write tool in the plugin's tool list. `download` is a read and stays allowed (ask-gated). The prefixes are a safety net for new tools. Read tools and `remember` match none of them.
- Capture and recall are on (the plugin's defaults). The plugin sends sessions to the server, tool output included, through the session API, and it injects recalled memories into prompts as hidden context. These do not go through MCP tools, so the name-based denies do not cover them.
- These denies are name-based guards, not a hard guarantee. Inside the sandbox the session holds the full API key (`OPENVIKING_API_KEY`) and shell is allowed, so a prompt-injected agent could call the server directly with `curl` and bypass them. Real enforcement needs a server-side key scoped to read + remember.
- Unsandboxed Claude (`claude-unsandboxed`, pinned dir `$XDG_STATE_HOME/claude-code`) loads the same OpenViking MCP plugin (`hm`) and the same deny list, from the pinned `settings.json`.
- Residual risks:
  - The session can read `OPENVIKING_API_KEY` from its environment.
  - `remember` can store untrusted content that later sessions read.
  - Transcripts, tool output included, are sent to the OpenViking server by the plugin's capture.
  - Recalled memories are injected into prompts as hidden context.
  - The npm plugin runs with access to the key. It is pinned, and a bump is manual.
  - The plugin writes logs and state to `~/.config/opencode/openviking`, which is read-only in the sandbox. Not verified whether this breaks it. If it does, point `OPENVIKING_CLI_CONFIG_FILE` at a generated JSON with `{"plugin":{"opencode":{"dataDir":"<state dir>/opencode/openviking"}}}`.
  - Sandboxed Claude Code runs with `bypassPermissions`, so its reads are not prompted; only the deny list applies.
  - The URL `/mcp` is assumed, not checked against the server.
- Not verified yet:
  - That the plugin loads on OpenCode v2 at runtime: after a service restart, the sandbox installs it from npm, and `node` is on the sandbox PATH.

## Figma (design files)

Figma's official remote MCP is in `figma.nix`, shared through `programs.mcp` by OpenCode and Claude Code.

- Auth is OAuth in the browser on first use. No token is stored in the config.
- Unsandboxed OpenCode asks for every `figma_*` call. The sandbox allows them, as it does shell and edit (`programs.nono.relaxedActions`, applied in `sandbox/opencode.nix`). Sandboxed Claude runs with `bypassPermissions`; unsandboxed Claude keeps its default prompts.
- Hosts: `mcp.figma.com`, `www.figma.com`, `api.figma.com`. Not verified: Figma's OAuth metadata could not be fetched, so the authorization and token hosts are a guess.
- Not verified in the sandbox: the OAuth callback port (OpenCode has `open_port_range`, the Claude profile has none) and token storage (the Keychain is denied).
- Accepted risks:
  - Sandboxed agents can write to Figma without a prompt. A prompt-injected agent could write data it can read into a Figma file or comment. This is an exfiltration path the user accepted; the instructions say never to do it.
  - The MCP OAuth token probably sits in a directory the session can read (the OpenCode data dir, the sandboxed Claude config dir). Not verified.
  - The `figma_*` allow applies to every agent, read-only ones and the orchestrator included.
  - Accepted risk: sandboxed OpenCode loads the repo's project `opencode.json`, because `OPENCODE_DISABLE_PROJECT_CONFIG` is not set. `sandbox/default.nix` does not deny writes to `opencode.json` or `.opencode`, so the session can write them, and that config can override the permission asks. Unsandboxed OpenCode loads it too.

## What the sandbox enforces

- Unsandboxed OpenCode uses the strict global rules. Sandboxed OpenCode loads a generated config through `OPENCODE_CONFIG_DIR`: the same config, where the asks of `programs.nono.relaxedActions` (shell, edit, figma__, atlassian__, openviking__; see `sandbox/opencode.nix`) become allow, so nono is the boundary. The other asks stay: the `subagent dev` gate and the slack MCP asks. Deny rules and the `experimental.policies` hard denies are unchanged in both modes. The Claude Code alias runs with `bypassPermissions` from its sandbox config dir for the same reason. Do not set `session.permissions: autoaccept` in `cli.json`: it bypasses the `dev` gate.
- The orchestrator's shell is not read-only. Its only permission limits are the global shell asks and the rules in `agents.nix`. Outside the sandbox that means prompts; inside, nono is the boundary, and the shell asks are relaxed to allow.
- Writes only in the project folder, the plan folder and a few state folders. Worktrees live under `~/.local/state/workmux/`, which the session cannot write directly.
- The launcher exports `WM_WORKTREES` (the project's `$XDG_STATE_HOME/workmux/worktrees/<project>`), granted read-write in the harness, so the session can write every worktree of the current project. Git run from inside a sibling worktree gets that worktree through `@git:toplevel`. The path-based denies (`.git`, `.claude`, `.mcp.json`, `.workmux.yaml`) still apply there. The helper falls back to `/var/empty` outside a git repo.
- The session itself has no zellij socket. The brokered `workmux` command does have it (`workmux.nix`), so an approved `workmux add` can open a tab. The zellij server runs outside the sandbox, so that tab, the agent in it, hooks and pane commands from `.workmux.yaml` are started unsandboxed. A prompt-injected session can run commands outside the sandbox through an approved workmux call, so read the command before you approve it.
- `open`, `dashboard` and `sidebar` are not part of this flow and are not verified in the sandbox.
- Git writes go through a broker. The session's git edge denies the `config` subcommand and the argv token `-c`, and denies writes to `.git/config`, `.git/hooks` and linked-worktree config and hooks. Accepted gap: `--git-dir`, `-C` and `--config-env` are not denied, so they can point git at another repo or config. The workmux edge allows `config` and `.git/config` writes, and denies hooks. Neither edge restricts ref updates.
- Network: all domains are allowed through the nono proxy on purpose (`allow_domain = [ "*" ]`). A domain list is not a secret boundary. A prompt-injected session can send any secret it holds in the sandbox anywhere, e.g. `OPENVIKING_API_KEY` (set through `set_vars`, which bypasses `deny_vars`).
- The orchestrator's `worktree`, `merge` and `coordinator` skills open multiplexer windows, and `open-pr` needs `gh`. All four are denied. The orchestrator calls the `workmux` CLI directly.

## Known gaps

- Not verified: `git worktree` under the broker, whether workmux stores metadata via `git config` (denied on the session's git edge; the workmux edge allows it), and `workmux merge`/`remove` behaviour without a multiplexer.
- Not verified at runtime: the zellij socket regex, `ZELLIJ*` env passing, and `-b -P` prompt delivery. To test, run `workmux list`, then `workmux add t -b` from the sandboxed session. If it fails, check `log stream --predicate 'sender == "Sandbox"'`.
- Not verified: whether the starship prompt runs git in a worktree the session wrote.
- Not verified: hard links to protected files bypass the path rules.
- Git broker writes (`git apply`, `checkout -- <file>`, `am`, `cherry-pick`, `worktree add` of a branch) run in the broker's sandbox and can still create `.claude/`, `.mcp.json`, `.workmux.yaml` or `.workmux.yml` in the tree. Review diffs and look for these files before running `workmux open` or `merge` unsandboxed. Accepted: not denied in the broker, because git would fail midway on repos that track these files.
- workmux finds project config by walking up the tree (`.workmux.yaml` and `.workmux.yml`). The Seatbelt rule is a speed bump, not a boundary.
- Not verified: the interactive TUI.
- The plan gate is a prompt rule, not a hard lock.
- A nested repo planted in a subfolder can escape the git guard, which protects only the project's own `.git`.
- Open decision: commits go through the orchestrator. The alternative is to commit through `dev`.
