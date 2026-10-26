{ inputs, ... }:
{
  flake.modules.homeManager.workmux =
    hmArgs@{ lib, pkgs, ... }:
    let
      workmux = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.workmux;
    in
    {
      home.packages = [ workmux ];
      home.shellAliases.wm = "workmux";

      # Run by the sandboxed session through the command broker. Every call asks.
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
              "$HOME/.opencode/plan"
            ];
            fs_read_file = [ "@git:config-files" ];
            fs_write = [
              "$WORKDIR"
              "@git:common-dir"
              "@git:worktree"
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
            # The zellij server runs outside the sandbox, so approved workmux calls can start
            # panes and their commands unsandboxed. The user accepts this for normal `workmux add`.
            # Rules before the denies; the denies stay last.
            unsafe_macos_seatbelt_rules = [
              ''(allow process-exec* (subpath "/nix/store"))''
              ''(allow network-outbound (remote unix-socket (path-regex #"^/(private/)?var/folders/[^/]+/[^/]+/T/zellij-[0-9]+/.*")))''
              ''(allow file-read* file-write* (regex #"^/(private/)?var/folders/[^/]+/[^/]+/T/zellij-[0-9]+(/.*)?$"))''
              ''(deny file-write* (regex #"/\.[gG][iI][tT]/([cC][oO][nN][fF][iI][gG](\.[wW][oO][rR][kK][tT][rR][eE][eE])?|[hH][oO][oO][kK][sS](/.*)?|([wW][oO][rR][kK][tT][rR][eE][eE][sS]|[mM][oO][dD][uU][lL][eE][sS])/.+/([cC][oO][nN][fF][iI][gG](\.[wW][oO][rR][kK][tT][rR][eE][eE])?|[hH][oO][oO][kK][sS](/.*)?))$"))''
              ''(deny file-write* (regex #"/(\.[cC][lL][aA][uU][dD][eE](/.*)?|\.[mM][cC][pP]\.[jJ][sS][oO][nN]|\.[wW][oO][rR][kK][mM][uU][xX]\.[yY][aA]?[mM][lL])$"))''
            ];
          };
          invocation_policy.default = "approve";
        };
      };

      xdg.configFile."workmux/config.yaml".source =
        (pkgs.formats.yaml { }).generate "workmux-config.yaml"
          {
            agent = "opencode";
            merge_strategy = "rebase";
            nerdfont = false;
            worktree_dir = "${hmArgs.config.xdg.stateHome}/workmux/worktrees/{project}";
            panes = [
              {
                command = "<agent>";
                focus = true;
              }
            ];
            files = {
              symlink = [
                "<global>"
                ".pnpm-store"
                ".envrc"
              ];
            };
            post_create = [
              "<global>"
              ''git ls-files -z -- ".envrc" "**/.envrc" | while IFS= read -r -d ""; do direnv allow "$REPLY" || true; done''
            ];
          };
    };
}
