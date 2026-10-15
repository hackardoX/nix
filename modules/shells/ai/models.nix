{
  flake.modules.homeManager.hackardo = {
    programs.opencode.settings.agents = {
      architect.model = "proton-lumo/lumo-max";
      security.model = "proton-lumo/lumo-max";
      # TODO: change back to proton-lumo/lumo-max
      dev.model = "proton-lumo/lumo-max";
      qa.model = "proton-lumo/lumo-max";
    };
  };

  flake.modules.homeManager.aaccardo = {
    programs.opencode.settings.agents = {
      architect.model = "anthropic/claude-opus-5-5";
      security.model = "anthropic/claude-opus-5-5";
      # TODO: change back to proton-lumo/lumo-max
      dev.model = "anthropic/claude-haiku-5-5";
      qa.model = "anthropic/claude-haiku-5-5";
    };
  };
}
