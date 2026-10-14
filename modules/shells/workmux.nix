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
            # New worktree paths are untrusted by direnv, so its .envrc files
            # would stay blocked until allowed by hand. Allow every tracked
            # .envrc, not just a root one: in the Proton monorepo the only
            # .envrc is nested (project/calendar/.envrc). Loop over
            # `git ls-files -z` instead of piping to xargs because BSD xargs
            # lacks -r and would run `direnv allow` on the cwd for an empty
            # list, exiting 1 and aborting `workmux add`; `|| true` keeps one
            # failing file from doing the same.
            post_create = [
              ''git ls-files -z -- ".envrc" "**/.envrc" | while IFS= read -r -d ""; do direnv allow "$REPLY" || true; done''
            ];
          };
    };
}
