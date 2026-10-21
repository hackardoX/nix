{ inputs, ... }:
{
  flake.modules.homeManager.dev =
    { pkgs, ... }:
    {
      home.packages = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.workmux ];
      home.shellAliases.wm = "workmux";

      xdg.configFile."workmux/config.yaml".source =
        (pkgs.formats.yaml { }).generate "workmux-config.yaml"
          {
            agent = "opencode";
            # Inside the project, so the sandbox $WORKDIR grant covers it and the
            # session cannot reach other projects' worktrees.
            worktree_dir = ".worktrees";
            merge_strategy = "rebase";
            nerdfont = false;
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
