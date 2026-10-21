{ config, ... }:
{
  flake.modules.homeManager.dev =
    hmArgs@{ lib, pkgs, ... }:
    let
      cfg = hmArgs.config.programs.nono;
      home = hmArgs.config.home.homeDirectory;

      opencode = lib.getExe' hmArgs.config.programs.opencode.package "opencode2";

      lumoHost = lib.head (
        builtins.match "https?://([^/:]+).*" config.flake.meta.aiProviders.lumo.endpoint
      );

      settings = hmArgs.config.programs.opencode.settings;

      # Only listed relaxedActions turn ask into allow; the subagent gate and MCP asks stay.
      relax = map (
        r:
        if r.effect == "ask" && builtins.elem r.action cfg.relaxedActions then
          r // { effect = "allow"; }
        else
          r
      );

      sandboxSettings = settings // {
        permissions = relax (settings.permissions or [ ]) ++ [
          {
            action = "external_directory";
            resource = "*";
            effect = "allow";
          }
        ];
        agents = lib.mapAttrs (
          _: a: a // lib.optionalAttrs (a ? permissions) { permissions = relax a.permissions; }
        ) (settings.agents or { });
      };

      # Replaces ~/.config/opencode (OPENCODE_CONFIG_DIR, bug #32825): link every file it reads.
      # Names are explicit (a pure build cannot list the dir); service.json is deliberately absent.
      sandboxConfigDir = pkgs.linkFarm "opencode-sandbox-config" (
        [
          {
            name = "opencode.json";
            path = pkgs.writeText "opencode.json" (builtins.toJSON sandboxSettings);
          }
        ]
        ++
          map
            (n: {
              name = n;
              path = "${home}/.config/opencode/${n}";
            })
            [
              "AGENTS.md"
              "cli.json"
              "tui.json"
              "skills"
              "plugins"
              "package.json"
              "node_modules"
            ]
      );
    in
    {
      options.programs.nono.relaxedActions = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Permission actions whose `ask` rules become `allow` in the sandboxed
          OpenCode config (nono is the boundary for them). Modules add their own
          actions, e.g. `figma_*`.
        '';
      };

      config = {
        programs.nono.relaxedActions = [
          "shell"
          "edit"
        ];

        # --standalone: a private server, so tool execution stays inside the sandbox.
        programs.nono.harnesses.opencode = {
          description = "OpenCode agent sandbox";
          command = "${opencode} --standalone";
          env = {
            # Trade-off: project AGENTS.md, opencode.json and plugins are not loaded.
            OPENCODE_DISABLE_PROJECT_CONFIG = "1";
            OPENCODE_TEST_HOME = "$WORKDIR";
            # Fail-safe: if OpenCode ignores this, it falls back to the strict global config.
            OPENCODE_CONFIG_DIR = "$XDG_STATE_HOME/opencode/sandbox-config";
          };
          allow = [
            "$XDG_DATA_HOME/opencode"
            "$XDG_CACHE_HOME/opencode"
            "$XDG_STATE_HOME/opencode"
            "$HOME/.opencode/plan"
            "$HOME/.local/share/opentui"
          ];
          read = [
            "$XDG_CONFIG_HOME/opencode"
            "$XDG_CONFIG_HOME/workmux"
            "$HOME/.claude"
            # OpenCode probes this at startup and crashes when missing.
            "$HOME/.opencode"
          ];
          domains = [
            "models.dev"
            "opencode.ai"
            lumoHost
          ];
          extra.network = {
            open_port_range = [
              [
                49152
                65535
              ]
            ];
          };
        };

        # A real directory (symlinks to the farm entries) in the state dir that the sandbox may write,
        # which also keeps the farm in the generation: OpenCode mkdirs OPENCODE_CONFIG_DIR at startup
        # and a store path fails with EPERM.
        xdg.stateFile."opencode/sandbox-config" = {
          source = sandboxConfigDir;
          recursive = true;
        };

        home.file.".opencode/plan/.keep".text = "";
        home.shellAliases.opencode-unsandboxed = "opencode2";
      };
    };
}
