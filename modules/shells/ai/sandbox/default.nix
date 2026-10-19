{ inputs, ... }:
{
  flake.modules.homeManager.dev =
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
              set_vars = {
                GLAB_CHECK_UPDATE = "false";
                GLAB_SEND_TELEMETRY = "false";
                GLAB_NO_PROMPT = "1";
                GLAB_BROWSER = "/usr/bin/false";
                GLAB_CONFIG_DIR = "$XDG_STATE_HOME/opencode/glab";
              }
              // a.env
              // cfg.env;
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
      options.programs.nono = {
        allowDomains = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = ''
            Extra domains the sandboxed harnesses may reach through the nono
            proxy. Entries may be sops placeholders
            (e.g. `config.sops.placeholder."gitlab/host"`) because the profile
            is rendered at activation by sops-nix, so secret hosts work too.
          '';
        };

        readPaths = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Extra directories the sandboxed harnesses may read (e.g. reference clones).";
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

        commandPolicies = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
          description = ''
            Top-level `command_policies` of every sandboxed profile (nono's
            brokered commands). Emitted only when non-empty.
          '';
        };

        harnesses = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, ... }:
              {
                options = {
                  description = lib.mkOption {
                    type = lib.types.str;
                    description = "Profile description (`meta.description`).";
                  };

                  alias = lib.mkOption {
                    type = lib.types.str;
                    default = name;
                    description = "Name of the interactive shell alias that starts the sandboxed agent.";
                  };

                  command = lib.mkOption {
                    type = lib.types.str;
                    description = "Command run inside the sandbox, after `--`.";
                  };

                  env = lib.mkOption {
                    type = lib.types.attrsOf lib.types.str;
                    default = { };
                    description = ''
                      Environment variables for this harness's session only, through
                      the profile's `environment.set_vars`. Set vars bypass
                      `deny_vars` (e.g. `*_TOKEN`), so use only for secrets the
                      session may hold. Values may be sops placeholders. Kept per
                      harness so a token never reaches the other harnesses' sessions.
                    '';
                  };

                  allow = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ ];
                    description = "Directories the agent may read and write.";
                  };

                  read = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ ];
                    description = "Directories the agent may read.";
                  };

                  allowFile = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ ];
                    description = "Single files the agent may read and write (`allow_file`).";
                  };

                  domains = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ ];
                    description = "Domains this agent may reach, in addition to programs.nono.allowDomains.";
                  };

                  extra = lib.mkOption {
                    type = lib.types.attrsOf lib.types.anything;
                    default = { };
                    description = ''
                      Profile sections deep-merged over the shared skeleton (e.g.
                      `network.open_port_range`).
                    '';
                  };
                };
              }
            )
          );
          default = { };
          description = "Sandboxed harnesses. Each one gets a profile `nono-<name>.json` and a shell alias.";
        };
      };

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
