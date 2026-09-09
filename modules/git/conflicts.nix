{
  flake.modules.homeManager.dev = {
    programs = {
      git = {
        settings = {
          pager.diff = "diffnav";
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
