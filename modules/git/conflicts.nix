{
  flake.modules.homeManager.dev = {
    programs = {
      git = {
        settings = {
          merge.tool = "nvimdiff";
          merge.conflictstyle = "zdiff3";
          rerere.enabled = true;
        };
      };
      mergiraf = {
        enable = true;
        enableGitIntegration = true;
      };
    };
  };
}
