{ config, inputs, ... }:
{
  flake.modules.homeManager.dev =
    hmArgs@{ lib, pkgs, ... }:
    let
      cfg = hmArgs.config.programs.opencode.sandbox;
      home = hmArgs.config.home.homeDirectory;

      nono = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.nono;
      opencode = lib.getExe' hmArgs.config.programs.opencode.package "opencode2";

      # Rendered sops templates that git needs to read (identity, includeIf,
      # allowed signers). Everything else rendered by sops stays denied.
      gitRendered = lib.pipe (lib.attrByPath [ "sops" "templates" ] { } hmArgs.config) [
        (lib.filterAttrs (name: _: name == "allowed_signers" || lib.hasPrefix "git-" name))
        (lib.mapAttrsToList (_: template: template.path))
      ];

      lumoHost = lib.head (
        builtins.match "https?://([^/:]+).*" config.flake.meta.aiProviders.lumo.endpoint
      );

      gitSigning = hmArgs.config.programs.git.signing;
      # ssh-keygen, or 1Password's op-ssh-sign.
      signerName = builtins.unsafeDiscardStringContext (baseNameOf gitSigning.signer);

      # Scratch space for git's signing buffer. It must stay outside the
      # session's grants, otherwise the agent could rewrite what gets signed.
      gitTmp = "${home}/.local/state/opencode-git/tmp";

      # Subcommands that create signed commits.
      signingSubcommands = [
        "commit"
        "merge"
        "rebase"
        "cherry-pick"
        "revert"
        "am"
      ];

      gitReal = lib.getExe hmArgs.config.programs.git.package;

      # Hooks the repository may define. Brokered git runs with its own hooks
      # directory (below), so these forward to the repository's hooks, whose
      # location the wrapper passes in OPENCODE_REPO_HOOKS.
      forwardedHooks = [
        "applypatch-msg"
        "pre-applypatch"
        "post-applypatch"
        "pre-commit"
        "pre-merge-commit"
        "prepare-commit-msg"
        "commit-msg"
        "post-commit"
        "pre-rebase"
        "post-checkout"
        "post-merge"
        "post-rewrite"
      ];

      # Refuses every ref update except the branch the session started on, so
      # brokered git cannot move other branches (main included). Git calls it
      # for every ref update, whatever command caused it, so this also holds
      # for `git branch -f`, `git update-ref` and the like.
      referenceGuard = pkgs.writeShellScript "reference-transaction" ''
        state=$1
        input=$(cat)

        refuse() {
          echo "git: this sandbox may only update $own (refused: $1)." >&2
          exit 1
        }

        if [ "$state" = prepared ] && [ -n "''${OPENCODE_GUARD:-}" ]; then
          own="refs/heads/''${OPENCODE_OWN_BRANCH:-}"
          while read -r _ new ref; do
            case "$ref" in
              "$own" | refs/stash | refs/bisect/* | refs/rewritten/*) ;;
              ORIG_HEAD | AUTO_MERGE | MERGE_HEAD | CHERRY_PICK_HEAD | REVERT_HEAD | REBASE_HEAD) ;;
              HEAD)
                # Detaching (rebase, checkout of a commit) is fine; switching
                # to another branch is not.
                case "$new" in
                  ref:*) [ "$new" = "ref:$own" ] || refuse "$new" ;;
                esac
                ;;
              *) refuse "$ref" ;;
            esac
          done <<< "$input"
        fi

        hook="''${OPENCODE_REPO_HOOKS:-}/reference-transaction"
        if [ -x "$hook" ]; then
          printf '%s\n' "$input" | "$hook" "$@"
        fi
      '';

      gitHooks = pkgs.linkFarm "opencode-git-hooks" (
        lib.genAttrs forwardedHooks (
          name:
          pkgs.writeShellScript name ''
            hook="''${OPENCODE_REPO_HOOKS:-}/${name}"
            [ -x "$hook" ] || exit 0
            exec "$hook" "$@"
          ''
        )
        // {
          reference-transaction = referenceGuard;
        }
      );

      # The pinned `git` executable. Global options can redirect git (--git-dir,
      # --work-tree, --config-env, ...) and nono only matches whole arguments,
      # so they are refused here, before the real git starts.
      gitGuard = pkgs.writeShellScript "git-guard" ''
        pre=()
        while [ $# -gt 0 ]; do
          case "$1" in
            --no-pager | --no-optional-locks)
              pre+=("$1")
              shift
              ;;
            -C)
              [ $# -ge 2 ] || exit 129
              pre+=("$1" "$2")
              shift 2
              ;;
            -*)
              echo "git: the global option $1 is not allowed in the sandbox." >&2
              exit 129
              ;;
            *) break ;;
          esac
        done
        # Git execs the signer by absolute path, which bypasses the nono shim.
        # The bare name goes through the broker instead.
        exec ${gitReal} \
          -c gpg.ssh.program=${signerName} \
          -c maintenance.auto=false \
          -c core.hooksPath=${gitHooks} \
          "''${pre[@]}" "$@"
      '';

      inherit (cfg) glab;
      glabEnabled = glab.tokenFile != null && glab.hostFile != null;
      glabReal = lib.getExe pkgs.glab;
      glabTmp = "${home}/.local/state/opencode-glab/tmp";

      # The pinned `glab` executable. The token never enters the session: this
      # script reads it inside glab's own sandbox, and only runs read-only
      # subcommands. The token itself only has the read_api scope, and the
      # sandbox only lets glab reach the GitLab host.
      glabGuard = pkgs.writeShellScript "glab-guard" ''
        set -eu

        deny() {
          echo "glab: $1 is not allowed in the sandbox (read-only access)." >&2
          exit 1
        }

        # Combined and attached short flags (-XPOST, -Rhost/x) hide values from
        # the checks below, and a repository flag may not name another host.
        for arg in "$@"; do
          case "$arg" in
            --hostname | --hostname=* | -w | --web) deny "$arg" ;;
            -[A-Za-z][A-Za-z]*) deny "$arg" ;;
            -R=* | --repo=* | *://*) deny "$arg" ;;
          esac
        done

        case "''${1:-}" in
          api)
            # One endpoint and a few flags, nothing that sends a body.
            shift
            endpoints=0
            for arg in "$@"; do
              case "$arg" in
                --paginate | -i | --include | --silent) ;;
                -*) deny "api $arg" ;;
                graphql | @* | *@* | http*) deny "api $arg" ;;
                *)
                  case "$arg" in
                    *[!A-Za-z0-9_%:./?=\&,-]*) deny "api $arg" ;;
                  esac
                  endpoints=$((endpoints + 1))
                  ;;
              esac
            done
            [ "$endpoints" -eq 1 ] || deny "api with $endpoints endpoints"
            set -- api "$@"
            ;;
          mr | issue | ci | repo | release)
            case "$1 ''${2:-}" in
              "mr view" | "mr list" | "mr diff" | "mr issues" | "mr approvers") ;;
              "issue view" | "issue list") ;;
              "ci status" | "ci list" | "ci view" | "ci get" | "ci trace") ;;
              "repo view") ;;
              "release view" | "release list") ;;
              *) deny "glab $1 ''${2:-}" ;;
            esac
            ;;
          --version | version) ;;
          *) deny "glab ''${1:-}" ;;
        esac

        GITLAB_TOKEN=$(${pkgs.coreutils}/bin/cat ${glab.tokenFile})
        GITLAB_HOST=$(${pkgs.coreutils}/bin/cat ${glab.hostFile})
        export GITLAB_TOKEN GITLAB_HOST
        # Settings come from here only, not from the session or from a
        # repository's .git/glab-cli/config.yml.
        export HOME=${glabTmp} XDG_CONFIG_HOME=${glabTmp} GLAB_CONFIG_DIR=${glabTmp}
        export GLAB_CHECK_UPDATE=false GLAB_SEND_TELEMETRY=false GLAB_NO_PROMPT=1
        export GLAB_PAGER=cat PAGER=cat GLAB_BROWSER=/usr/bin/false GLAB_EDITOR=/usr/bin/false
        export GLAB_API_PROTOCOL=https GLAB_SKIP_TLS_VERIFY=false
        export GIT_CEILING_DIRECTORIES=/
        exec ${glabReal} "$@"
      '';

      commandEnv.allow_vars = [
        "PATH"
        "HOME"
        "USER"
        "LOGNAME"
        "LANG"
        "LC_*"
        "TERM"
      ];

      baseProfile = {
        meta = {
          name = "opencode";
          description = "OpenCode agent sandbox";
        };
        extends = "default";

        groups.include = [
          "nix_runtime"
          "git_config"
          "user_caches_macos"
          "node_runtime"
          "rust_runtime"
          "python_runtime"
          "go_runtime"
          "go_runtime_macos"
          "unlink_protection"
        ];

        workdir.access = "readwrite";

        # The agent needs its provider key, but not forge tokens: with those it
        # could push over HTTPS to hosts the proxy allows.
        environment.deny_vars = [
          "*_TOKEN"
          "*SECRET*"
          "*PASSWORD*"
          "SSH_AUTH_SOCK"
        ];

        filesystem = {
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
          ];
          read_file = gitRendered;
          bypass_protection = gitRendered;
          unix_socket = [ "/nix/var/nix/daemon-socket/socket" ];
          deny = [
            # Holds the password of the unsandboxed background service.
            "$XDG_CONFIG_HOME/opencode/service.json"
            "$XDG_CONFIG_HOME/nono"
            # Decrypted secrets: sops-nix mounts them under $TMPDIR/secrets.d.
            "$XDG_CONFIG_HOME/sops"
            "$XDG_CONFIG_HOME/sops-nix"
            "$TMPDIR/secrets.d"
            # SSH agent sockets.
            "$TMPDIR/proton-pass-agent"
            "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password"
          ];
        };

        # Proxy mode also denies Unix sockets (e.g. the SSH agent) by default,
        # which plain filesystem rules do not.
        network = {
          network_profile = "developer";
          allow_domain = [
            "models.dev"
            "opencode.ai"
            lumoHost
            "proxy.golang.org"
            "sum.golang.org"
          ]
          ++ cfg.allowDomains;
          # The private OpenCode server binds an OS-assigned port. macOS caps
          # port rules at 16384, which is the whole ephemeral range.
          open_port_range = [
            [
              49152
              65535
            ]
          ];
        };

        # OpenCode resolves the folders above the project (and a few well-known
        # ones) while discovering instructions, and crashes if it cannot. These
        # rules only let it see that they exist: children stay denied. The
        # wrapper adds the parents of the project at launch.
        unsafe_macos_seatbelt_rules = [
          ''(allow file-read* (literal "${home}"))''
          ''(allow file-read* (literal "${home}/.opencode"))''
        ];

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

          # The real git must not be reachable around the guard.
          deny_direct_exec_bypass = [ gitReal ] ++ lib.optional glabEnabled glabReal;

          credentials.ssh-agent = {
            type = "local-socket";
            path = "$SSH_AUTH_SOCK";
            mode = "connect";
            env_var = "SSH_AUTH_SOCK";
          };

          commands.git = {
            executable = gitGuard;
            can_use = [ signerName ];

            from.session = {
              sandbox = {
                fs_read_file = [ "@git:config-files" ];
                fs_read = [
                  "/nix/store"
                  "$XDG_CONFIG_HOME/git"
                  "@git:hooks-path"
                ];
                fs_write = [
                  "$WORKDIR"
                  "@git:common-dir"
                  gitTmp
                ];
                environment = commandEnv // {
                  set_vars.TMPDIR = gitTmp;
                };
                # The pinned executable is the guard script. nono only lets it
                # run itself and its interpreter, so the real git, its helpers
                # and the hook scripts need exec permission explicitly.
                unsafe_macos_seatbelt_rules = [
                  ''(allow process-exec* (subpath "/nix/store"))''
                ];
              };

              invocation_policy = {
                default = "allow";
                deny = [
                  {
                    argv.contains = [ "push" ];
                    reason = "Pushing is done by the user.";
                  }
                  {
                    argv.contains = [ "fetch" ];
                    reason = "The sandbox has no network access to remotes.";
                  }
                  {
                    argv.contains = [ "pull" ];
                    reason = "The sandbox has no network access to remotes.";
                  }
                  {
                    argv.contains = [ "tag" ];
                    reason = "Tags are signed outside the commit approval.";
                  }
                  {
                    argv.contains = [ "commit-tree" ];
                    reason = "Plumbing would sign outside the commit approval.";
                  }
                  {
                    argv.contains = [ "-c" ];
                    reason = "Config overrides could redirect signing.";
                  }
                ];
              };
            };

            intercept = lib.optionals cfg.approveCommits (
              map (subcommand: {
                args = [ subcommand ];
                action.type = "approve";
              }) signingSubcommands
            );
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
      };

      # Read-only GitLab access for the agent, in a command sandbox of its own.
      # The host is only known at launch (see launchJq).
      glabProfile = lib.optionalAttrs glabEnabled {
        command_policies.commands.glab = {
          executable = glabGuard;
          from.session.sandbox = {
            fs_read = [
              "/nix/store"
              "$WORKDIR"
            ];
            fs_read_file = [
              glab.tokenFile
              glab.hostFile
            ];
            fs_write = [ glabTmp ];
            environment = commandEnv // {
              # glab only reaches the host through the proxy nono gives it.
              allow_vars = commandEnv.allow_vars ++ [
                "HTTPS_PROXY"
                "HTTP_PROXY"
                "ALL_PROXY"
                "NO_PROXY"
                "https_proxy"
                "http_proxy"
                "all_proxy"
                "no_proxy"
              ];
              set_vars.TMPDIR = glabTmp;
            };
            network.allow_domain = [ ];
            unsafe_macos_seatbelt_rules = [
              ''(allow process-exec* (subpath "/nix/store"))''
            ];
          };
        };
      };

      profile = lib.recursiveUpdate baseProfile glabProfile;

      profileFile = pkgs.writeText "nono-opencode.json" (builtins.toJSON profile);

      # Seatbelt rules for one folder above the project, read from stdin as
      # newline-separated paths. OpenCode probes each such folder for config and
      # instruction files and crashes on a denied path, so it may list the
      # folder, stat what is directly inside it, and read the names it loads.
      parentRulesJq = pkgs.writeText "parent-rules.jq" ''
        def esc: gsub("(?<c>[.^$*+?(){}|\\[\\]\\\\])"; "\\\(.c)");
        split("\n") | map(select(length > 0)) | map(
          "(allow file-read* (literal \(@json)))",
          "(allow file-read-metadata (regex #\"^\(esc)/[^/]+$\"))",
          "(allow file-read* (regex #\"^\(esc)/(opencode\\.jsonc?|AGENTS\\.md|CLAUDE\\.md)$\"))",
          ((".claude", ".opencode", ".agents") as $n | "(allow file-read* (subpath \"\(.)/\($n)\"))")
        )
      '';

      # Per-launch edits to the profile. $parents are the seatbelt rules from
      # parentRulesJq. The git rules need the repository's paths, so they only
      # apply inside one.
      #
      # The session may read git state but never write it: a hook or config
      # entry planted there would run unsandboxed the next time git is used on
      # the checkout. Brokered git may write it, except hooks and config, and
      # may only move the branch the session started on (see referenceGuard).
      # It gets the absolute paths here because the static grants are relative
      # to the launch folder, and git also needs to read the whole checkout when
      # OpenCode starts in a subfolder.
      launchJq = pkgs.writeText "launch.jq" ''
        def esc: gsub("(?<c>[.^$*+?(){}|\\[\\]\\\\])"; "\\\(.c)");
        .unsafe_macos_seatbelt_rules += $parents
        | if $common == "" then . else
            .unsafe_macos_seatbelt_rules += [
              "(deny file-write* (subpath \($common | @json)))",
              "(deny file-write* (subpath \("\($toplevel)/.git" | @json)))"
            ]
            | .command_policies.commands.git.from.session.sandbox |= (
                .fs_write += [$common]
                | .fs_read += [$toplevel]
                | .unsafe_macos_seatbelt_rules += [
                  "(deny file-write* (subpath \("\($common)/hooks" | @json)))",
                  "(deny file-write* (literal \("\($common)/config" | @json)))",
                  "(deny file-write* (literal \("\($common)/config.worktree" | @json)))",
                  "(deny file-write* (literal \("\($toplevel)/.git" | @json)))",
                  "(deny file-write* (regex #\"^\($common | esc)/(worktrees|modules)/.+/(config\\.worktree|config|hooks)(/.*)?$\"))"
                ]
                | .environment.set_vars += {
                    OPENCODE_GUARD: "1",
                    OPENCODE_OWN_BRANCH: $own,
                    OPENCODE_REPO_HOOKS: $hooks
                  }
              )
          end
        | if $glabhost == "" then del(.command_policies.commands.glab)
          else
            .network.allow_domain += [$glabhost]
            | .command_policies.commands.glab.from.session.sandbox.network.allow_domain = [$glabhost]
          end
      '';

      # The private server (--standalone) keeps tool execution inside the
      # sandbox. The shared background service would run tools outside it.
      wrapper = pkgs.writeShellApplication {
        name = "opencode";
        runtimeInputs = [
          nono
          pkgs.git
          pkgs.jq
          pkgs.coreutils
        ];
        text = ''
          run_dir=""

          cleanup() {
            [ -z "$run_dir" ] || rm -rf "$run_dir"
          }

          case "''${1:-}" in
            acp | api | auth | debug | mcp | models | plugin | service | session | stats | uninstall | update | upgrade)
              exec ${opencode} "$@"
              ;;
          esac

          sub=()
          case "''${1:-}" in
            run | mini)
              sub=("$1")
              shift
              ;;
            *)
              if [ $# -gt 0 ] && [ -d "$1" ]; then
                cd "$1"
                shift
              fi
              ;;
          esac

          case "$PWD" in
            "$HOME" | / | /Users | "$HOME/Library"*)
              echo "opencode: refusing to sandbox $PWD, it is too broad." >&2
              echo "cd into a project, or use opencode-unsandboxed." >&2
              exit 1
              ;;
          esac

          # Git state is only ever written by the brokered git. A linked
          # worktree keeps its state in the main repository, which the session
          # may read.
          grants=()
          common=""
          toplevel=""
          own=""
          repo_hooks=""
          linked=0
          if common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null); then
            toplevel=$(git rev-parse --show-toplevel)
            own=$(git symbolic-ref --quiet --short HEAD || true)
            repo_hooks=$(git rev-parse --path-format=absolute --git-path hooks)
            gitdir=$(git rev-parse --path-format=absolute --git-dir)
            [ "$gitdir" = "$common" ] || linked=1
            grants+=(--read "$common")
          else
            common=""
          fi

          # Outside the folders the sandbox may write to, so it cannot alter the
          # profile generated below.
          state="''${XDG_STATE_HOME:-$HOME/.local/state}/opencode-run"
          mkdir -p "$state"
          run_dir=$(mktemp -d "$state/run.XXXXXX")
          trap cleanup EXIT

          # Let the sandbox see each folder above the project (see parentRulesJq).
          parents=()
          dir=$PWD
          while [ "$dir" != "/" ]; do
            dir=$(dirname "$dir")
            [ "$dir" = "/" ] || parents+=("$dir")
          done
          rules='[]'
          if [ "''${#parents[@]}" -gt 0 ]; then
            rules=$(printf '%s\n' "''${parents[@]}" | jq -R -s -c -f ${parentRulesJq})
          fi

          # Per-launch rules: protect the git state and scope git writes to the
          # branch this session started on (see launchJq).
          glab_host=""
          ${lib.optionalString glabEnabled "glab_host=$(cat ${glab.hostFile} 2>/dev/null || true)"}

          profile=${profileFile}
          if jq \
            --argjson parents "$rules" \
            --arg glabhost "$glab_host" \
            --arg common "$common" \
            --arg toplevel "$toplevel" \
            --arg own "$own" \
            --arg hooks "$repo_hooks" \
            -f ${launchJq} ${profileFile} > "$run_dir/profile.json"; then
            profile="$run_dir/profile.json"
          fi

          # In a linked worktree the agent only risks its own branch, so its
          # permission prompts are replaced by the sandbox. Explicit denies
          # still apply.
          flags=(--standalone)
          if [ "$linked" = 1 ] && [ "''${sub[0]:-}" != mini ]; then
            flags+=(--auto)
          fi

          nono run --silent --profile "$profile" --allow-cwd "''${grants[@]}" \
            -- ${opencode} "''${sub[@]}" "''${flags[@]}" "$@"
        '';
      };
    in
    {
      options.programs.opencode.sandbox = {
        glab = {
          tokenFile = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = ''
              File holding a GitLab token with only the read_api scope. Set it
              together with hostFile to let the agent run read-only glab commands.
              The token never enters the session's own sandbox.
            '';
          };
          hostFile = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "File holding the GitLab host name. It is the only host glab may reach.";
          };
        };

        allowDomains = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Extra domains the sandboxed OpenCode may reach through the nono proxy.";
        };

        approveCommits = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Ask for approval in the terminal (nono) before git creates a signed
            commit. Disable to rely on the OpenCode permission prompt alone.
          '';
        };
      };

      config = {
        home.file.".local/state/opencode-git/tmp/.keep".text = "";
        home.file.".opencode/plan/.keep".text = "";
        home.file.".local/state/opencode-glab/tmp/.keep".text = "";

        home.packages = [
          nono
          wrapper
        ];
        home.shellAliases.opencode-unsandboxed = "opencode2";
        xdg.configFile."nono/profiles/opencode.json".source = profileFile;
      };
    };
}
