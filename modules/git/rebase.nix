{
  flake.modules.homeManager.git = {
    programs.git.settings.rebase = {
      autoStash = true;
      updateRefs = true;
    };
  };
}
