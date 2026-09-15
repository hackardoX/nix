{
  flake.modules.homeManager.dev = {
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
