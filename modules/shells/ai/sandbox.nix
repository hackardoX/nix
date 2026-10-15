{ config, inputs, ... }:
{
  flake.modules.homeManager.dev =
    hmArgs@{ lib, pkgs, ... }:
    let
      cfg = hmArgs.config.programs.opencode.sandbox;
      home = hmArgs.config.home.homeDirectory;

      nono = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.nono;
      opencode = lib.getExe' hmArgs.config.programs.opencode.package "opencode2";

      lumoHost = lib.head (
        builtins.match "https?://([^/:]+).*" config.flake.meta.aiProviders.lumo.endpoint
      );

      gitSigning = hmArgs.config.programs.git.signing;
      # ssh-keygen, or 1Password's op-ssh-sign.
      signerName = builtins.unsafeDiscardStringContext (baseNameOf gitSigning.signer);

      # Scratch space for git's signing buffer. It must stay outside the
      # session's grants, otherwise the agent could rewrite what gets signed.
      gitTmp = "${hmArgs.config.xdg.stateHome}/opencode-git/tmp";

      gitReal = lib.getExe hmArgs.config.programs.git.package;

      # Final merged settings (opencode.nix, agents.nix, jira.nix, ...), same
      # values Home Manager renders into ~/.config/opencode.json.
      settings = hmArgs.config.programs.opencode.settings;

      # Nono is the boundary for shell and edit: their asks become allow here.
      # Every other ask stays, including the `subagent` plan gate and the MCP
      # asks (atlassian_*, slack_*). Deny rules, agent allowlists and
      # experimental.policies are untouched.
      relax = map (
        r:
        if
          r.effect == "ask"
          && builtins.elem r.action [
            "shell"
            "edit"
          ]
        then
          r // { effect = "allow"; }
        else
          r
      );

      sandboxSettings = settings // {
        permissions = relax (settings.permissions or [ ]) ++ [
          {
            action = "external_directory";
            resource = "*";
            effect = "allow";
          }
        ];
        agents = lib.mapAttrs (
          _: a: a // lib.optionalAttrs (a ? permissions) { permissions = relax a.permissions; }
        ) (settings.agents or { });
      };

      # Complete replacement for ~/.config/opencode (OPENCODE_CONFIG_DIR
      # replaces it in v2, upstream bug #32825), so every file the unsandboxed
      # config reads must be linked here. Names are explicit because a pure
      # build cannot list the real dir: a new file there needs a new entry.
      # service.json is deliberately absent (it holds the service password).
      # AGENTS.md and tui.json are HM store symlinks; the rest are real files
      # or dirs. The agents' system prompts are already embedded in the settings.
      sandboxConfigDir = pkgs.linkFarm "opencode-sandbox-config" (
        [
          {
            name = "opencode.json";
            path = pkgs.writeText "opencode.json" (builtins.toJSON sandboxSettings);
          }
        ]
        ++
          map
            (n: {
              name = n;
              path = "${home}/.config/opencode/${n}";
            })
            [
              "AGENTS.md"
              "cli.json"
              "tui.json"
              "skills"
              "plugins"
              "package.json"
              "node_modules"
            ]
      );

      commandEnv.allow_vars = [
        "PATH"
        "HOME"
        "USER"
        "LOGNAME"
        "LANG"
        "LC_*"
        "TERM"
      ];

      # Brokered git is default-deny on subcommands. It can write .git, and
      # config/init/clone/remote/worktree/submodule could plant hooks or config
      # that run unsandboxed later (e.g. `git init --template`,
      # `git config core.hooksPath`), so those stay denied. Global options
      # (--git-dir, --work-tree, --config-env, ...) cannot redirect git
      # because no argv.prefix matches a call that starts with one; the
      # default deny catches it. `-C <path>` calls are not matched because
      # argv must start with the subcommand; accepted for this experiment.
      gitAllowedSubcommands = [
        "status"
        "diff"
        "log"
        "show"
        "add"
        "commit"
        "switch"
        "restore"
        "branch"
        "stash"
        "rev-parse"
        "ls-files"
        "blame"
        "merge"
        "rebase"
        "cherry-pick"
        "revert"
        "am"
        "reset"
        "checkout"
        "rm"
        "mv"
        "grep"
        "describe"
        "shortlog"
        "diff-tree"
        "show-ref"
        "symbolic-ref"
        "cat-file"
        "ls-tree"
        "merge-base"
        "var"
        "name-rev"
        "apply"
      ];

      # Shared skeleton of the sandboxed agent profiles. Agent-specific parts
      # arrive through the arguments: extra set_vars, filesystem grants, extra
      # domains, and `extra`, which is deep-merged for whole profile sections
      # (e.g. network.open_port_range). Lists keep the caller's order, so
      # callers control the rendered JSON exactly.
      mkProfile =
        {
          name,
          description,
          setVars ? { },
          allow ? [ ],
          read ? [ ],
          allowFile ? [ ],
          domains ? [ ],
          extra ? { },
        }:
        lib.recursiveUpdate {
          meta = {
            inherit name description;
          };
          extends = "default";

          groups.include = [
            "nix_runtime"
            "user_caches_macos"
            "node_runtime"
            "rust_runtime"
            "python_runtime"
            "go_runtime"
            "unlink_protection"
          ];

          workdir.access = "readwrite";

          environment = {
            set_vars = {
              # glab would otherwise try to update-check, phone home or prompt
              # in the read-only config dir.
              GLAB_CHECK_UPDATE = "false";
              GLAB_SEND_TELEMETRY = "false";
              GLAB_NO_PROMPT = "1";
              # Never open a browser for the OAuth login flow inside the
              # session; the agent only has the token from cfg.env.
              GLAB_BROWSER = "/usr/bin/false";
              # Fresh glab config dir; glab creates it itself and it sits
              # under the already writable $XDG_STATE_HOME/opencode grant.
              # Agents without that grant override this in their setVars.
              GLAB_CONFIG_DIR = "$XDG_STATE_HOME/opencode/glab";
            }
            // setVars
            // cfg.env;
            # Forge tokens are denied so the agent cannot push over HTTPS. Set
            # vars (cfg.env) bypass these patterns on purpose.
            deny_vars = [
              "*_TOKEN"
              "*SECRET*"
              "*PASSWORD*"
              "SSH_AUTH_SOCK"
            ];
          };

          filesystem = {
            inherit allow;
            read = read ++ cfg.readPaths;
            unix_socket = [ "/nix/var/nix/daemon-socket/socket" ];
            deny = [
              # Holds the password of the unsandboxed background service.
              "$XDG_CONFIG_HOME/opencode/service.json"
              "$XDG_CONFIG_HOME/nono"
              # Decrypted secrets: sops-nix mounts them under $TMPDIR/secrets.d.
              "$XDG_CONFIG_HOME/sops"
              "$XDG_CONFIG_HOME/sops-nix"
              "$TMPDIR/secrets.d"
              # SSH agent sockets. Keychains are denied by nono's default
              # deny_keychains_macos group.
              "$TMPDIR/proton-pass-agent"
              # The session must never write git state: a planted hook or config
              # would run unsandboxed later. Only brokered git touches it. This
              # also blocks reads.
              "$WORKDIR/.git"
            ];
          }
          // lib.optionalAttrs (allowFile != [ ]) {
            # nono's key for single-file read+write grants (`nono profile
            # schema`). Only set when non-empty: an empty list would change
            # the rendered profile.
            allow_file = allowFile;
          };

          # Proxy mode also denies Unix sockets (e.g. the SSH agent) by
          # default, which plain filesystem rules do not.
          network = {
            network_profile = "developer";
            allow_domain =
              domains
              ++ [
                "proxy.golang.org"
                "sum.golang.org"
              ]
              ++ cfg.allowDomains;
          };

          # Git runs outside the session's sandbox, in its own, so the SSH agent
          # never reaches the agent: only a brokered git can sign, via ssh-keygen.
          command_policies = {
            approval_backends.terminal = {
              type = "terminal";
              timeout_secs = 120;
            };
            approval_defaults = {
              backend = "terminal";
              timeout_secs = 120;
            };

            # The real git must not be reachable around the broker.
            deny_direct_exec_bypass = [ gitReal ];

            credentials.ssh-agent = {
              type = "local-socket";
              path = "$SSH_AUTH_SOCK";
              mode = "connect";
              env_var = "SSH_AUTH_SOCK";
            };

            commands.git = {
              executable = gitReal;
              can_use = [ signerName ];

              from.session = {
                sandbox = {
                  fs_read_file = [ "@git:config-files" ];
                  fs_read = [
                    "/nix/store"
                    "$XDG_CONFIG_HOME/git"
                  ];
                  fs_write = [
                    "$WORKDIR"
                    "@git:common-dir"
                    gitTmp
                  ];
                  environment = commandEnv // {
                    # Git execs the signer by absolute path from its config,
                    # which bypasses the nono shim; env config overrides
                    # config files, and the agent cannot set it because the
                    # broker env only passes allow_vars plus these.
                    set_vars = {
                      TMPDIR = gitTmp;
                      GIT_CONFIG_COUNT = "2";
                      GIT_CONFIG_KEY_0 = "gpg.ssh.program";
                      GIT_CONFIG_VALUE_0 = signerName;
                      GIT_CONFIG_KEY_1 = "maintenance.auto";
                      GIT_CONFIG_VALUE_1 = "false";
                    };
                  };
                  # The pinned executable is now real git, so the exec rule is
                  # kept until tested (it may be redundant). Static regex
                  # because the per-launch rules are gone; it covers `.git`
                  # directories incl. linked worktrees and submodules, not
                  # bare repos not named `.git`. Appended rules are emitted
                  # last so the deny wins.
                  unsafe_macos_seatbelt_rules = [
                    ''(allow process-exec* (subpath "/nix/store"))''
                    ''(deny file-write* (regex #"/\.git/(config(\.worktree)?|hooks(/.*)?|(worktrees|modules)/.+/(config(\.worktree)?|hooks(/.*)?))$"))''
                  ];
                };

                invocation_policy = {
                  default = "deny";
                  allow = map (subcommand: {
                    argv.prefix = [ subcommand ];
                    reason = "Allowed git subcommand.";
                  }) gitAllowedSubcommands;
                  # Explicit denies so their reasons still show.
                  deny = [
                    {
                      argv.contains = [ "push" ];
                      reason = "Pushing is done by the user.";
                    }
                    {
                      argv.contains = [ "tag" ];
                      reason = "Tags are signed outside the commit approval.";
                    }
                    {
                      argv.contains = [ "commit-tree" ];
                      reason = "Plumbing would sign outside the commit approval.";
                    }
                  ];
                };
              };
            };

            commands.${signerName} = {
              executable = gitSigning.signer;
              from = {
                session = "deny";
                git = {
                  fs_read = [ "/nix/store" ];
                  fs_read_file = [
                    gitSigning.key
                    # Lets `git log --show-signature` verify instead of saying U.
                    hmArgs.config.sops.templates."allowed_signers".path
                  ];
                  fs_write = [ gitTmp ];
                  use_credentials = [ "ssh-agent" ];
                  environment = commandEnv;
                };
              };
            };
          };
        } extra;
    in
    {
      options.programs.opencode.sandbox = {
        allowDomains = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = ''
            Extra domains the sandboxed agents may reach through the nono
            proxy. Entries may be sops placeholders
            (e.g. `config.sops.placeholder."gitlab/host"`) because the profile
            is rendered at activation by sops-nix, so secret hosts work too.
          '';
        };

        readPaths = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Extra directories the sandboxed agents may read (e.g. reference clones).";
        };

        env = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = ''
            Environment variables injected into every sandboxed agent session
            through the profile's `environment.set_vars`. Set vars bypass
            `deny_vars` (e.g. `*_TOKEN`), so use only for secrets the session
            may hold. Values may be sops placeholders, because the profile is
            rendered at activation by sops-nix.
          '';
        };

        approveCommits = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Ask for approval in the terminal (nono) before git creates a signed
            commit. Disable to rely on the agent's own permission prompt alone.
          '';
        };

        mkProfile = lib.mkOption {
          type = lib.types.raw;
          internal = true;
          readOnly = true;
          default = mkProfile;
          description = "Builder for the shared nono agent profiles (see sandbox.nix).";
        };
      };

      options.programs.claude-code.sandbox.env = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = ''
          Environment variables injected into the Claude Code session only,
          through the profile's `environment.set_vars`. Set vars bypass
          `deny_vars` (e.g. `*_TOKEN`), so use only for secrets the session may
          hold. Values may be sops placeholders. Kept apart from the shared
          `sandbox.env` so this token never reaches the OpenCode sessions.
        '';
      };

      config = {
        xdg.stateFile."opencode-git/tmp/.keep".text = "";
        home.file.".opencode/plan/.keep".text = "";

        home.packages = [ nono ];

        # The profile stays out of the Nix store because allowDomains may hold
        # secret hosts; sops renders it at activation and substitutes the
        # `<SOPS:...>` placeholder strings (builtins.toJSON leaves them
        # untouched). Declared unconditionally on purpose: gating it on
        # allowDomains would make `sops.templates` depend on
        # `sops.placeholder`, which sops-nix itself defines in terms of
        # `sops.templates` (infinite recursion). A template without
        # placeholders just renders to identical content.
        # sops-nix defaults apply: mode 0400, owned by the user, under
        # $XDG_CONFIG_HOME/sops-nix/secrets/rendered.
        sops.templates."nono-opencode.json".content = builtins.toJSON (mkProfile {
          name = "opencode";
          description = "OpenCode agent sandbox";
          setVars = {
            # Skip OpenCode's parent-folder/project discovery walk (compat
            # workaround from nono's upstream opencode pack). Trade-off: project
            # AGENTS.md/opencode.json/plugins are not loaded.
            OPENCODE_DISABLE_PROJECT_CONFIG = "1";
            OPENCODE_TEST_HOME = "$WORKDIR";
            # Nonono-only config: in v2 this replaces ~/.config/opencode for
            # this process (upstream bug #32825 may make it additive later),
            # so the generated dir is a complete config with the relaxed
            # sandbox rules. Fail-safe: if OpenCode ever ignores it, the
            # sandbox falls back to the strict global config.
            OPENCODE_CONFIG_DIR = "${sandboxConfigDir}";
          };
          allow = [
            "$XDG_DATA_HOME/opencode"
            "$XDG_CACHE_HOME/opencode"
            "$XDG_STATE_HOME/opencode"
            # Where the orchestrator saves approved plans for workmux.
            "$HOME/.opencode/plan"
            # OpenTUI parser data; without it markdown is not rendered (nono#245).
            "$HOME/.local/share/opentui"
          ];
          read = [
            "$XDG_CONFIG_HOME/opencode"
            "$HOME/.claude"
            # OpenCode probes this at startup and crashes when it is missing.
            "$HOME/.opencode"
          ];
          domains = [
            "models.dev"
            "opencode.ai"
            lumoHost
          ];
          extra.network = {
            # The private OpenCode server binds an OS-assigned port. macOS caps
            # port rules at 16384, which is the whole ephemeral range.
            open_port_range = [
              [
                49152
                65535
              ]
            ];
          };
        });

        # Aliases exist in interactive shells only, so scripts and login shells
        # cannot reach the sandboxed entry point (fails closed). Subcommands
        # that need the real binary (auth, models, service, upgrade, ...) must
        # go through opencode-unsandboxed. Dropped from the old wrapper: the
        # --auto flag (not a v2 mechanism; the generated config via
        # OPENCODE_CONFIG_DIR replaces it) and refusing a broad $PWD; nono
        # itself should refuse to grant a parent of its protected state dir,
        # i.e. $HOME.
        #
        # --standalone starts a private server so tool execution stays inside
        # the sandbox; the shared background service would run tools outside it.
        home.shellAliases.opencode = "nono run --silent --profile ${
          hmArgs.config.sops.templates."nono-opencode.json".path
        } --allow-cwd -- ${opencode} --standalone";
        home.shellAliases.opencode-unsandboxed = "opencode2";

        sops.templates."nono-claude-code.json".content = builtins.toJSON (mkProfile {
          name = "claude-code";
          description = "Claude Code agent sandbox";
          setVars = {
            CLAUDE_CONFIG_DIR = "$XDG_STATE_HOME/claude-code";
            GLAB_CONFIG_DIR = "$XDG_STATE_HOME/claude-code/glab";
            DISABLE_AUTOUPDATER = "1";
            CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
          }
          // hmArgs.config.programs.claude-code.sandbox.env;
          allow = [ "$XDG_STATE_HOME/claude-code" ];
          domains = [ "api.anthropic.com" ];
        });

        # nono is the boundary, so Claude Code skips its own permission prompts.
        home.shellAliases.claude = "nono run --silent --profile ${
          hmArgs.config.sops.templates."nono-claude-code.json".path
        } --allow-cwd -- ${lib.getExe hmArgs.config.programs.claude-code.finalPackage} --permission-mode bypassPermissions";
        home.shellAliases.claude-unsandboxed = lib.getExe hmArgs.config.programs.claude-code.finalPackage;
      };
    };
}
