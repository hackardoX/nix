{ inputs, ... }:
{
  flake.modules.homeManager.workmux =
    hmArgs@{ lib, pkgs, ... }:
    let
      sandboxedOpencode = hmArgs.config.programs.nono.harnesses ? opencode;

      workmux =
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.workmux.overrideAttrs
          (old: {
            # Skip the failing upstream test suite.
            postPatch = (old.postPatch or "") + ''
              substituteInPlace src/multiplexer/handshake.rs \
                --replace-fail "HANDSHAKE_TIMEOUT_SECS: u64 = 5;" "HANDSHAKE_TIMEOUT_SECS: u64 = 120;"
            '';
          });
    in
    {
      home.packages = [ workmux ];
      home.shellAliases.wm = "workmux";

      programs.git.ignores = [
        ".workmux.yaml"
      ];

      # Run by the sandboxed session through the command broker.
      programs.nono.commandPolicies.commands.workmux = {
        executable = lib.getExe workmux;
        can_use = [ "git" ];
        from.session = {
          sandbox = {
            fs_read = [
              "/nix/store"
              "$XDG_CONFIG_HOME/workmux"
              "$XDG_CONFIG_HOME/git"
              # workmux reads the prompt file passed with `add -P`.
              "$XDG_STATE_HOME/opencode/plan"
            ];
            fs_read_file = [ "@git:config-files" ];
            fs_write = [
              "$WORKDIR"
              "@git:common-dir"
              "@git:worktree"
              # `@git:worktree` is empty in the main checkout; see the git edge (git-broker.nix).
              "@git:toplevel"
              "$XDG_STATE_HOME/workmux"
              "$XDG_CACHE_HOME/workmux"
            ];
            environment.allow_vars = [
              "PATH"
              "HOME"
              "USER"
              "LOGNAME"
              "LANG"
              "LC_*"
              "TERM"
              "SHELL"
              "XDG_*"
              # zellij detection (ZELLIJ, ZELLIJ_SESSION_NAME, ZELLIJ_PANE_ID); TMPDIR locates its socket dir.
              "ZELLIJ*"
              "TMPDIR"
            ];
            # Hooks from .workmux.yaml run inside this sandbox. Git itself writes .git/config
            # through its own edge (sandbox/git-broker.nix), not this process.
            # The zellij server runs outside the sandbox, so workmux calls can start
            # panes and their commands unsandboxed.
            unsafe_macos_seatbelt_rules = [
              ''(allow process-exec* (subpath "/nix/store"))''
              ''(allow network-outbound (remote unix-socket (path-regex #"^/(private/)?var/folders/[^/]+/[^/]+/T/zellij-[0-9]+/.*")))''
              ''(allow file-read* file-write* (regex #"^/(private/)?var/folders/[^/]+/[^/]+/T/zellij-[0-9]+(/.*)?$"))''
              # workmux's zellij pane handshake FIFO in $TMPDIR (mkfifo, open, unlink).
              ''(allow file-read* file-write* (regex #"^/(private/)?var/folders/[^/]+/[^/]+/T/workmux_pipe_[0-9]+_[0-9]+$"))''
              # Prompt files (workmux-prompt-*.md) and other markdown under workmux*/opencode* in $TMPDIR.
              ''(allow file-read* file-write* (regex #"^/(private/)?var/folders/[^/]+/[^/]+/T/(workmux|opencode)[^/]*(/.*\.md)?$"))''
              # mktemp in hooks (e.g. pre_remove). Default template only (tmp.XXXXXX), not the whole
              ''(allow file-read* file-write* (regex #"^/(private/)?var/folders/[^/]+/[^/]+/T/tmp\.[A-Za-z0-9]+(/.*)?$"))''
              # direnv data dir (allow/ and deny/ stores), used by the post_create hook. The whole
              ''(allow file-read* file-write* (regex #"^${lib.escapeRegex hmArgs.config.xdg.dataHome}/direnv(/.*)?$"))''
            ];
          };
          invocation_policy = {
            # TODO: to be replaced once nono fix PTY handling properly
            default = "allow";
          };
        };
      };

      xdg.configFile."workmux/config.yaml".source =
        (pkgs.formats.yaml { }).generate "workmux-config.yaml"
          {
            agent = if sandboxedOpencode then "opencode-sandboxed" else "opencode2";
            base_branch = "auto";
            merge_strategy = "rebase";
            nerdfont = true;
            worktree_dir = "${hmArgs.config.xdg.stateHome}/workmux/worktrees/{project}";
            panes = [
              {
                command = "<agent>";
                focus = true;
              }
            ];
            # post_create = [
            #   ''git ls-files -z -- ':(glob)**/.envrc' | while IFS= read -r -d "" f; do direnv allow "$f" && direnv exec "$(dirname "$f")" true; done''
            # ];
            agents = lib.optionalAttrs sandboxedOpencode {
              opencode-sandboxed = {
                type = "opencode";
                command = "nono-opencode";
              };
            };
          };

      xdg.configFile."opencode/plugins/workmux-status" = {
        enable = hmArgs.config.programs.opencode.enable;
        source = "${
          inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.workmux
        }/resources/opencode/v2/workmux-status";
        recursive = true;
      };
    };
}
