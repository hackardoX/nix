{ inputs, ... }:
{
  flake.modules.homeManager.dev =
    { pkgs, ... }:
    {
      home.packages = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.workmux ];
      home.shellAliases.wm = "workmux";

      # Set explicitly: workmux prompts for these on first run and would then
      # fail to write them back to a read-only, managed config.
      xdg.configFile."workmux/config.yaml".source =
        (pkgs.formats.yaml { }).generate "workmux-config.yaml"
          {
            agent = "opencode";
            nerdfont = false;
            # A single pane on purpose: Zellij ignores `new-pane --cwd` for plain
            # shells, so a second pane would open in the main checkout instead of
            # the worktree. The first pane is started inside the worktree.
            panes = [
              {
                command = "<agent>";
                focus = true;
              }
            ];
          };
    };
}
