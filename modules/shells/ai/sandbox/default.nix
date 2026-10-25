{ inputs, ... }:
{
  flake.modules.homeManager.nono =
    hmArgs@{ lib, pkgs, ... }:
    let
      cfg = hmArgs.config.programs.nono;

      nono = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.nono;

      profilePath = name: hmArgs.config.sops.templates."nono-${name}.json".path;

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
              inherit (a) allow;
              read = a.read ++ cfg.readPaths;
              unix_socket = [ "/nix/var/nix/daemon-socket/socket" ];
              deny = [
                "$XDG_CONFIG_HOME/opencode/service.json"
                "$XDG_CONFIG_HOME/nono"
                "$XDG_CONFIG_HOME/sops"
                "$XDG_CONFIG_HOME/sops-nix"
                "$TMPDIR/secrets.d"
                "$TMPDIR/proton-pass-agent"
                # Session must not write git state: planted hooks would run unsandboxed later.
                "$WORKDIR/.git"
              ];
            }
            // lib.optionalAttrs (a.allowFile != [ ]) {
              # nono's key for single-file read+write grants.
              allow_file = a.allowFile;
            };

            network = {
              network_profile = "developer";
              allow_domain =
                a.domains
                ++ [
                  "proxy.golang.org"
                  "sum.golang.org"
                ]
                ++ cfg.allowDomains;
            };

            # Stops planted project config (hooks, MCP servers) running unsandboxed later.
            # Static regex: the workdir is only known at launch.
            unsafe_macos_seatbelt_rules = [
              ''(deny file-write* (regex #"/\.claude(/.*)?$"))''
              ''(deny file-write* (regex #"/\.mcp\.json$"))''
            ];
          }
          // lib.optionalAttrs (cfg.commandPolicies != { }) {
            command_policies = cfg.commandPolicies;
          }
        ) a.extra;
    in
    {
      config = {
        home.packages = [ nono ];

        # Rendered at activation so secret hosts stay out of the store.
        # Unconditional: gating on allowDomains recurses via sops.placeholder.
        sops.templates = lib.mapAttrs' (
          name: a: lib.nameValuePair "nono-${name}.json" { content = builtins.toJSON (mkProfile name a); }
        ) cfg.harnesses;

        # Interactive shells only, so scripts fail closed.
        home.shellAliases = lib.mapAttrs' (
          name: a:
          lib.nameValuePair a.alias "nono run --silent --profile ${profilePath name} --allow-cwd -- ${a.command}"
        ) cfg.harnesses;
      };
    };
}
