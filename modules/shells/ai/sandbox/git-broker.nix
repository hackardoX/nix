{
  flake.modules.homeManager.nono =
    hmArgs@{ lib, pkgs, ... }:
    let
      gitSigning = hmArgs.config.programs.git.signing;
      signerName = builtins.unsafeDiscardStringContext (baseNameOf gitSigning.signer);

      # Must stay outside the session's grants, or the agent could rewrite what is signed.
      gitTmp = "${hmArgs.config.xdg.stateHome}/opencode-git/tmp";

      gitReal = lib.getExe hmArgs.config.programs.git.package;

      sshReal = lib.getExe' pkgs.openssh "ssh";

      commandEnv.allow_vars = [
        "PATH"
        "HOME"
        "USER"
        "LOGNAME"
        "LANG"
        "LC_*"
        "TERM"
      ];

      # Shared by the session and workmux edges.
      gitSandboxBase = {
        fs_read_file = [ "@git:config-files" ];
        fs_read = [
          "/nix/store"
          "$XDG_CONFIG_HOME/git"
        ];
        # core.fsmonitor: git talks to (and may start) the per-worktree fsmonitor daemon.
        unix_socket_bind = [ "@git:fsmonitor-socket" ];
        environment = commandEnv // {
          # Git execs the signer by absolute path, bypassing the nono shim. This env
          # config overrides files, and the agent cannot set it.
          set_vars = {
            TMPDIR = gitTmp;
            GIT_CONFIG_COUNT = "2";
            GIT_CONFIG_KEY_0 = "gpg.ssh.program";
            GIT_CONFIG_VALUE_0 = signerName;
            GIT_CONFIG_KEY_1 = "maintenance.auto";
            GIT_CONFIG_VALUE_1 = "false";
          };
        };
      };

      # Default-allow with a deny list. Prefix rules on subcommands never matched: leading
      # options such as `--git-dir` (OpenCode snapshots) or `-C` (workmux) push the
      # subcommand out of position 0. `contains` is position independent. Accepted gap:
      # `-C <path>` or `--git-dir` pointing at another repo is not restricted.
      # Plain `commit` is allowed; any prompt comes from the signer (ssh agent), not from
      # this policy. These denies stop tag and plumbing paths that would sign without
      # going through `commit`. The reason strings below are user-facing.
      gitBaseDenies = [
        {
          argv.contains = [ "tag" ];
          reason = "Tags are signed outside the commit approval.";
        }
        {
          argv.contains = [ "commit-tree" ];
          reason = "Plumbing would sign outside the commit approval.";
        }
      ];

      # The workmux edge never pushes and has no ssh access, so push stays denied there. The
      # session edge asks the user for each push instead (see `approve` below).
      gitWorkmuxDenies = gitBaseDenies ++ [
        {
          argv.contains = [ "push" ];
          reason = "Pushing is done by the user.";
        }
      ];

      # Session only: workmux itself runs worktree and prune, so those stay allowed there.
      gitSessionDenies = gitBaseDenies ++ [
        {
          argv.contains = [ "config" ];
          reason = "Can plant hooks or config that run unsandboxed later.";
        }
        {
          argv.contains = [ "init" ];
          reason = "Creates repos outside the reviewed checkout.";
        }
        {
          argv.contains = [ "clone" ];
          reason = "Creates repos outside the reviewed checkout.";
        }
        {
          argv.contains = [ "submodule" ];
          reason = "Can plant hooks or config through submodule git dirs.";
        }
        {
          argv.contains = [ "worktree" ];
          reason = "Worktrees are managed by workmux, not the session.";
        }
        {
          argv.contains = [ "-c" ];
          reason = "Config overrides can set hooks or program paths.";
        }
        {
          argv.contains = [ "replace" ];
          reason = "Rewrites what history shows.";
        }
        {
          argv.contains = [ "gc" ];
          reason = "Can delete objects that other work relies on.";
        }
        {
          argv.contains = [ "prune" ];
          reason = "Can delete objects that other work relies on.";
        }
        {
          argv.contains = [ "filter-branch" ];
          reason = "Rewrites history.";
        }
        {
          argv.contains = [ "fast-import" ];
          reason = "Writes objects and refs directly.";
        }
        {
          argv.contains = [ "update-ref" ];
          reason = "Moves refs directly, bypassing review.";
        }
        {
          argv.contains = [ "update-index" ];
          reason = "Writes the index directly.";
        }
      ];
    in
    {
      assertions = [
        {
          assertion = hmArgs.config.sops.templates ? "allowed_signers";
          message = "nono git broker requires the git-extras feature (sops template allowed_signers)";
        }
      ];

      programs.nono.commandPolicies = {
        approval_backends.terminal = {
          type = "terminal";
          timeout_secs = 120;
        };
        approval_defaults = {
          backend = "terminal";
          timeout_secs = 120;
        };

        # Real git must not be runnable around the broker.
        deny_direct_exec_bypass = [ gitReal ];

        credentials.ssh-agent = {
          type = "local-socket";
          path = "$SSH_AUTH_SOCK";
          mode = "connect";
          env_var = "SSH_AUTH_SOCK";
        };

        commands.git = {
          executable = gitReal;
          can_use = [
            signerName
            "ssh"
          ];

          from.session = {
            sandbox = gitSandboxBase // {
              fs_write = [
                "$WORKDIR"
                "@git:common-dir"
                "@git:toplevel"
                gitTmp
                # OpenCode snapshot repo, written via `git --git-dir`.
                "$XDG_DATA_HOME/opencode/snapshot"
              ];
              # Appended last so the deny wins. Static regex, case-insensitive via bracket
              # classes (APFS). Covers the .git dirs of checkouts (incl. linked worktrees and
              # submodules). Not bare repos or snapshot repos.
              unsafe_macos_seatbelt_rules = [
                ''(allow process-exec* (subpath "/nix/store"))''
                ''(deny file-write* (regex #"/\.[gG][iI][tT]/([cC][oO][nN][fF][iI][gG](\.[wW][oO][rR][kK][tT][rR][eE][eE])?|[hH][oO][oO][kK][sS](/.*)?|([wW][oO][rR][kK][tT][rR][eE][eE][sS]|[mM][oO][dD][uU][lL][eE][sS])/.+/([cC][oO][nN][fF][iI][gG](\.[wW][oO][rR][kK][tT][rR][eE][eE])?|[hH][oO][oO][kK][sS](/.*)?))$"))''
                # Linked-worktree admin files: a rewritten commondir/gitdir can redirect git
                # to a session-controlled config.
                ''(deny file-write* (regex #"/\.[gG][iI][tT]/(([wW][oO][rR][kK][tT][rR][eE][eE][sS]|[mM][oO][dD][uU][lL][eE][sS])/.+/)?([cC][oO][mM][mM][oO][nN][dD][iI][rR]|[gG][iI][tT][dD][iI][rR])$"))''
                # Project config that runs unsandboxed later (MCP, Claude hooks, workmux panes).
                ''(deny file-write* (regex #"/(\.[cC][lL][aA][uU][dD][eE](/.*)?|\.[mM][cC][pP]\.[jJ][sS][oO][nN]|\.[wW][oO][rR][kK][mM][uU][xX]\.[yY][aA]?[mM][lL])$"))''
              ];
            };

            # Push asks the user in the terminal every time. `contains` also matches
            # `git stash push`, which prompts too. Not matched: a remote-side
            # `--receive-pack=<cmd>` (one token), so read the prompt before approving.
            invocation_policy = {
              default = "allow";
              deny = gitSessionDenies;
              approve = [ { argv.contains = [ "push" ]; } ];
            };
          };

          # Workmux runs git for add/merge. Unlike the session, it may write .git/config, hooks,
          # protected project files and worktrees/<n>/{commondir,gitdir}: no path denies here, so
          # workmux add works on repos that track .claude/, .mcp.json or .workmux.yaml. Accepted:
          # a planted hook or config could run unsandboxed later; only the argv denies apply.
          from.workmux = {
            sandbox = gitSandboxBase // {
              fs_write = [
                "$WORKDIR"
                "@git:common-dir"
                "@git:worktree"
                "@git:toplevel"
                "$XDG_STATE_HOME/workmux"
                gitTmp
              ];
              unsafe_macos_seatbelt_rules = [
                ''(allow process-exec* (subpath "/nix/store"))''
              ];
            };

            invocation_policy = {
              default = "allow";
              deny = gitWorkmuxDenies;
            };
          };
        };

        # Git runs ssh for push and fetch over SSH remotes. Only git may call it (the session is
        # denied), so the agent socket and network are not reachable with arbitrary ssh args.
        # macOS cannot grant raw TCP/22 per port or per domain (allow_domain is an HTTP proxy
        # allowlist), hence allow_all. SSH config includes (sops templates) are listed
        # individually; $HOME/.ssh covers known_hosts, config and the .pub identity files.
        commands.ssh = {
          executable = sshReal;
          from = {
            session = "deny";
            git = {
              fs_read = [
                "/nix/store"
                "/etc/ssh"
                "$HOME/.ssh"
              ];
              fs_read_file = hmArgs.config.programs.ssh.includes;
              unsafe_macos_seatbelt_rules = [
                ''(allow process-exec* (subpath "/nix/store"))''
              ];
              network.allow_all = true;
              use_credentials = [ "ssh-agent" ];
              environment = commandEnv;
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
                hmArgs.config.sops.templates."allowed_signers".path
              ];
              fs_write = [ gitTmp ];
              use_credentials = [ "ssh-agent" ];
              environment = commandEnv;
            };
          };
        };
      };

      xdg.stateFile."opencode-git/tmp/.keep".text = "";
    };
}
