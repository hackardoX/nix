{
  flake.modules.homeManager.git-extras = {
    programs.git.settings.aliases.fetch = "git fetch --tags";
  };
}
