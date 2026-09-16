{
  flake.modules.homeManager.dev = { pkgs, ... }: {
    home.packages = with pkgs; [
      diffnav
    ];

    programs = {
      delta.enable = true;
      difftastic.enable = true;
      git.settings = {
        pager.diff = "diffnav";
        diff.algorithm = "histogram";
        difftool = {
          prompt = false;
          delta = {
            name = "Delta";
            trustExitCode = true;
            cmd = "delta $MERGED $LOCAL $REMOTE";
          };
          difft = {
            name = "Difftastic";
            trustExitCode = true;
            cmd = "difft $MERGED $LOCAL abcdef1 100644 $REMOTE abcdef2 100644";
          };
        };
      };
    };
  };
}
