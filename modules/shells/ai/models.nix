{
  flake.modules.homeManager.ai-models-lumo = {
    programs.opencode.settings.agents = {
      architect.model = "proton-lumo/lumo-max";
      security.model = "proton-lumo/lumo-max";
      dev.model = "proton-lumo/lumo-max";
      qa.model = "proton-lumo/lumo-max";
    };
  };

  flake.modules.homeManager.ai-models-anthropic = {
    programs.opencode.settings.agents = {
      architect.model = "anthropic/claude-opus-5-5";
      security.model = "anthropic/claude-opus-5-5";
      dev.model = "anthropic/claude-haiku-5-5";
      qa.model = "anthropic/claude-haiku-5-5";
    };
  };
}
