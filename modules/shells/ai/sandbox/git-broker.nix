{
  flake.modules.homeManager.dev =
    hmArgs@{ lib, ... }:
    let
      gitSigning = hmArgs.config.programs.git.signing;
      signerName = builtins.unsafeDiscardStringContext (baseNameOf gitSigning.signer);

      # Must stay outside the session's grants, or the agent could rewrite what is signed.
      gitTmp = "${hmArgs.config.xdg.stateHome}/opencode-git/tmp";

      gitReal = lib.getExe hmArgs.config.programs.git.package;

      commandEnv.allow_vars = [
        "PATH"
        "HOME"
        "USER"
        "LOGNAME"
        "LANG"
        "LC_*"
        "TERM"
      ];

      # Default-deny: config/init/clone/remote/submodule stay denied; they can
      # plant hooks or config that run unsandboxed later. Accepted gap: `-C <path>` calls.
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
        "worktree"
      ];
    in
    {
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
              # Appended last so the deny wins. Static regex: covers .git dirs (incl. worktrees,
              # submodules), not bare repos.
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
