{
  flake.modules.homeManager.ai-models-lumo = {
    programs.opencode.settings.agents.main.model = "proton-lumo/lumo-max";
  };

  flake.modules.homeManager.ai-models-anthropic = {
    programs.opencode.settings.agents.main.model = "anthropic/claude-sonnet-5-5";
  };
}
