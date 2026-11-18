{ inputs, ... }:
{
  flake.modules.homeManager.nono =
    hmArgs@{ lib, pkgs, ... }:
    let
      cfg = hmArgs.config.programs.nono;

      nono = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.nono;

      profilePath = name: hmArgs.config.sops.templates."nono-${name}.json".path;

      worktreesDir = pkgs.writeShellScriptBin "workmux-worktrees-dir" ''
        root=$(${lib.getExe pkgs.git} rev-parse --path-format=absolute --git-common-dir) || { echo /var/empty; exit; }
        dir=${hmArgs.config.xdg.stateHome}/workmux/worktrees/$(basename "$(dirname "$root")")
        mkdir -p "$dir"
        echo "$dir"
      '';

      # The session may start in a subdirectory (e.g. project/calendar/web). Brokered git run by
      # workmux works in the checkout root (`workmux merge` runs `git switch main` there), and
      # nono limits it to what the session can write, so the root must be granted too.
      toplevelDir = pkgs.writeShellScriptBin "workmux-toplevel-dir" ''
        ${lib.getExe pkgs.git} rev-parse --show-toplevel 2>/dev/null || echo /var/empty
      '';

      # Prints the profile as pretty JSON with sops placeholders instead of secret values, so it can
      # be shared with someone who does not use nix. The placeholders are hashes, not secrets.
      profileExporter =
        name:
        pkgs.writeShellScriptBin "nono-profile-${name}" ''
          exec ${lib.getExe pkgs.jq} . ${
            pkgs.writeText "nono-${name}.json" hmArgs.config.sops.templates."nono-${name}.json".content
          }
        '';

      mkProfile =
        name: a:
        lib.recursiveUpdate (
          {
            meta = {
              inherit name;
              inherit (a) description;
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
              set_vars = a.env // cfg.env;
              # Set vars (cfg.env and harness env) bypass deny_vars on purpose.
              deny_vars = [
                "*_TOKEN"
                "*SECRET*"
                "*PASSWORD*"
                "SSH_AUTH_SOCK"
              ];
            };

            filesystem = {
              allow = [ "$HOME/.cargo" ] ++ a.allow;
              read = cfg.readPaths ++ a.read;
              unix_socket = [ "/nix/var/nix/daemon-socket/socket" ];
              deny = [
                "$XDG_CONFIG_HOME/nono"
                "$XDG_CONFIG_HOME/sops"
                "$XDG_CONFIG_HOME/sops-nix"
                "$TMPDIR/secrets.d"
                "$TMPDIR/proton-pass-agent"
              ]
              ++ a.deny;
            }
            // lib.optionalAttrs (a.allowFile != [ ]) {
              # nono's key for single-file read+write grants.
              allow_file = a.allowFile;
            };

            network = {
              network_profile = "developer";
              allow_domain = [ "*" ];
            };

            # Stops planted project config running unsandboxed later: hooks, MCP servers,
            # workmux pane commands and hooks. Static regex: the workdir is only known at
            # launch. APFS is case-insensitive, so each name uses bracket classes.
            # The session never writes .git itself (git writes go through the broker, which
            # has its own sandbox). .git stays readable: nono refuses to run a brokered command
            # (e.g. `git worktree prune`, cwd .git) in a directory the session cannot access.
            # The .git rule also stops a rewritten linked-worktree
            # .git file that points gitdir: at a session-controlled config (fsmonitor,
            # hooksPath). .workmux.yaml/.yml would run pane commands and hooks when the user
            # later runs workmux.
            # OpenCode's sandbox config dir (OPENCODE_CONFIG_DIR, built by sandbox/opencode.nix) is a
            # real dir in the writable state dir: without this the session could replace its links
            # (e.g. set session.permissions autoaccept). Home Manager writes it from outside.
            # The last rule re-allows the cache dir (Seatbelt: the last matching rule wins): tools
            # create these names there as plain files and links, e.g. Bazel's execroot symlink
            # forest links the workspace's .claude and .git. Nothing in a cache is run unsandboxed.
            # The iokit-open rule lets Bazel's server register for system power events
            # (IORegisterForSystemPower); without it the server dies with
            # "CHECK failed: (suspend_state.connect_port) != (0)".
            unsafe_macos_seatbelt_rules = [
              ''(allow iokit-open (iokit-user-client-class "RootDomainUserClient"))''
              ''(allow file-write* (subpath "${hmArgs.config.xdg.cacheHome}"))''
              ''(deny file-write* (regex #"/\.[cC][lL][aA][uU][dD][eE](/.*)?$"))''
              ''(deny file-write* (regex #"/\.[mM][cC][pP]\.[jJ][sS][oO][nN]$"))''
              ''(deny file-write* (regex #"/\.[wW][oO][rR][kK][mM][uU][xX]\.[yY]([aA])?[mM][lL]$"))''
              ''(deny file-write* (regex #"/\.[gG][iI][tT](/.*)?$"))''
              ''(deny file-write* (regex #"/[oO][pP][eE][nN][cC][oO][dD][eE]/[sS][aA][nN][dD][bB][oO][xX]-[cC][oO][nN][fF][iI][gG](/.*)?$"))''
            ];
          }
          // lib.optionalAttrs (cfg.commandPolicies != { }) {
            command_policies = cfg.commandPolicies;
          }
        ) a.extra;
    in
    {
      config = {
        programs.nono.launchers = lib.mapAttrs (
          name: a:
          pkgs.writeShellScript "nono-${name}" ''
            export WM_WORKTREES=$(${lib.getExe worktreesDir})
            export WM_TOPLEVEL=$(${lib.getExe toplevelDir})
            exec ${nono}/bin/nono run --silent --profile ${profilePath name} --allow-cwd -- ${a.command} "$@"
          ''
        ) cfg.harnesses;

        home.packages = [
          nono
          worktreesDir
          toplevelDir
        ]
        ++ lib.mapAttrsToList (name: _: profileExporter name) cfg.harnesses;

        # Rendered at activation so secret hosts stay out of the store.
        # Unconditional: gating on harness values (env holds sops placeholders) recurses via sops.placeholder.
        sops.templates = lib.mapAttrs' (
          name: a: lib.nameValuePair "nono-${name}.json" { content = builtins.toJSON (mkProfile name a); }
        ) cfg.harnesses;

        # Interactive shells only, so scripts fail closed.
        home.shellAliases = lib.mapAttrs' (
          name: a: lib.nameValuePair a.alias "${cfg.launchers.${name}}"
        ) cfg.harnesses;
      };
    };
}
