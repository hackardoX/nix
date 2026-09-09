{
  flake.modules.homeManager.dev = {
    programs = {
      delta.enable = true;
      difftastic.enable = true;
      lazygit.settings.git = {
        diff = {
          externalDiffCommand = "difft --color=always";
        };
        diffRenderers = [
          { type = "extDiff"; }
          { command = "delta --dark --paging=never"; }
        ];
      };
      git.settings = {
        diff.algorithm = "histogram";
        difftool = {
          delta = {
            name = "Delta";
            trustExitCode = true;
            cmd = "delta $MERGED $LOCAL abcdef1 100644 $REMOTE abcdef2 100644";
            prompt = false;
          };
          difft = {
            name = "Difftastic";
            trustExitCode = true;
            cmd = "difft $MERGED $LOCAL abcdef1 100644 $REMOTE abcdef2 100644";
            prompt = false;
          };
        };
      };
    };
  };
}
