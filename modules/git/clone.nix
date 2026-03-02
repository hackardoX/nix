{
  flake.modules.homeManager.dev = {
    programs.git.settings.aliases.fetch = "git fetch --tags";
  };
}
