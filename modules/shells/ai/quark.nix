{
  flake.modules.homeManager.mcp-quark =
    hmArgs@{
      lib,
      options,
      pkgs,
      ...
    }:
    let
      # Agent instructions come from sops, not the Nix store. The file is copied
      # to a real file (not a symlink) because the nono sandbox cannot follow
      # symlinks into the sops secrets directory.
      secretPath = hmArgs.config.sops.secrets."ai/quark_instructions".path;
      instructionsPath = "${hmArgs.config.xdg.configHome}/opencode/quark-instructions.md";

      # Destructive tools, hard-denied. The names contain hyphens and it is
      # unverified whether OpenCode v2 keeps them in the permission string, so
      # both the hyphen and the underscore variant are generated.
      # The credential tools (user-issue-jwt, user-generate-magiclink) stay on ask.
      deniedTools = [
        "user-delete"
        "drive-volume-delete"
        "cal-calendar-delete"
        "cal-delete-by-address"
        "user-address-delete-all"
        "feature-value-delete"
      ];
      deniedVariants = lib.unique (
        deniedTools ++ map (tool: builtins.replaceStrings [ "-" ] [ "_" ] tool) deniedTools
      );

      # Under the opencode state dir because that is the only state dir the nono sandbox can write.
      workDir = "${hmArgs.config.xdg.stateHome}/opencode/quark-mcp";
    in
    {
      config = lib.mkMerge [
        {
          sops.secrets."ai/quark_instructions" = { };

          programs.opencode.settings = {
            instructions = [ instructionsPath ];

            mcp.servers.quark = {
              type = "local";
              command = [
                "/bin/sh"
                "-c"
                ''exec "$HOME/.quark-mcp/bin/cli.js"''
              ];
              # The server appends quark-mcp.log to its working directory.
              cwd = workDir;
            };

            # Every call asks, in the sandbox too (the sandbox relaxes only the
            # programs.nono.relaxedActions asks). Destructive tools are hard-denied below.
            permissions = [
              {
                action = "quark_*";
                resource = "*";
                effect = "ask";
              }
            ];

            # Hard denies, applied after agent rules and saved approvals, so no
            # allow rule can bypass them. Same list-merge as opencode.nix.
            experimental.policies = map (tool: {
              action = "permission";
              resource = "quark_${tool}:*";
              effect = "deny";
            }) deniedVariants;
          };

          # Dedicated working directory for the server's log file.
          xdg.stateFile."opencode/quark-mcp/.keep".text = "";

          # Copies the sops-managed instructions to a real file that OpenCode loads
          # via `instructions`. The secret is never printed. The source hash is in
          # the environment, so a changed sops file reloads the agent on switch.
          launchd.agents.quark-instructions = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
            enable = true;
            config = {
              ProgramArguments = [
                "${pkgs.bash}/bin/bash"
                "-c"
                ''
                  secret="${secretPath}"
                  dest="${instructionsPath}"
                  mkdir -p "$(dirname "$dest")"
                  for _ in $(seq 1 30); do
                    if [ -s "$secret" ] && ! ${pkgs.diffutils}/bin/cmp -s "$secret" "$dest"; then
                      ${pkgs.coreutils}/bin/install -m 0600 "$secret" "$dest"
                    fi
                    sleep 2
                  done
                ''
              ];
              EnvironmentVariables.QUARK_INSTRUCTIONS_SOURCE_SHA256 = builtins.hashFile "sha256" hmArgs.config.sops.defaultSopsFile;
              KeepAlive = false;
              RunAtLoad = true;
              StandardOutPath = "${hmArgs.config.xdg.stateHome}/quark-instructions.log";
              StandardErrorPath = "${hmArgs.config.xdg.stateHome}/quark-instructions.err.log";
            };
          };
        }
        # optional integration: sandbox read access only when the nono feature is present
        (lib.optionalAttrs (options.programs ? nono) {
          # The launcher lives under $HOME/.quark-mcp, which the sandbox cannot read by default.
          programs.nono.harnesses.opencode.read = [ "$HOME/.quark-mcp" ];
        })
      ];
    };
}
