{
  flake.modules.homeManager.dev = {
    # Models are intentionally not set, same as the agents.
    programs.opencode.settings.commands = {
      design = {
        description = "Design a change with the architect: read-only, returns a plan";
        agent = "architect";
        subagent = false;
        template = builtins.readFile ./commands/design.md;
      };

      review = {
        description = "Verify and review the current changes with QA";
        agent = "qa";
        template = builtins.readFile ./commands/review.md;
      };

      audit = {
        description = "Security review of the current changes";
        agent = "security";
        template = builtins.readFile ./commands/audit.md;
      };
    };
  };
}
