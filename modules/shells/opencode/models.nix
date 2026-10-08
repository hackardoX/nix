{
  # Models are per user; the shared agents.nix leaves them unset.
  flake.modules.homeManager.aaccardo = {
    programs.opencode.settings.agents = {
      architect.model = "anthropic/claude-opus-5-5";
      security.model = "anthropic/claude-opus-5-5";
      dev.model = "proton-lumo/lumo-max";
      qa.model = "proton-lumo/lumo-max";
    };
  };
}
