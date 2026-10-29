{ lib, ... }: {
  flake.modules.homeManager.nono = {
    options.programs.nono = {
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

      relaxedActions = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Permission actions whose `ask` rules become `allow` in the sandboxed
          OpenCode config (nono is the boundary for them). Modules add their own
          actions, e.g. `figma_*`.
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

      launchers = lib.mkOption {
        type = lib.types.attrsOf lib.types.package;
        readOnly = true;
        description = ''
          Per-harness executable that runs the harness in its nono sandbox. 
        '';
      };
    };
  };
}
