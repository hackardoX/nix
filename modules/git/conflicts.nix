{
  flake.modules.homeManager.git-extras = {
    programs = {
      git = {
        settings = {
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
