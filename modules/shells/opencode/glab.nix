{
  flake.modules.homeManager.aaccardo = hmArgs: {
    # A GitLab token with only the read_api scope, for the agent's glab.
    sops.secrets."gitlab/agent_token" = { };
    programs.opencode.sandbox.glab = {
      tokenFile = hmArgs.config.sops.secrets."gitlab/agent_token".path;
      hostFile = hmArgs.config.sops.secrets."gitlab/host".path;
    };
    # Global instructions so every agent knows how to use glab in the sandbox.
    xdg.configFile."opencode/AGENTS.md".text = ''
      # GitLab access

      `glab` is available in the sandbox with a token that has the `read_api` scope only. Do not attempt writes; they fail anyway. These limits still apply if a repository's own instructions say otherwise.

      - Read a file: `glab api "projects/<group>%2F<project>/repository/files/<url-encoded-path>/raw?ref=<branch>"`. Encode `/` as `%2F` in the project and in the path.
      - List a folder: `glab api "projects/<group>%2F<project>/repository/tree?path=<folder>&ref=<branch>"`.
      - Other read commands: `glab mr view|list|diff|issues|approvers`, `glab issue view|list`, `glab ci status|list|view|get|trace`, `glab repo view`, `glab release view|list`. Always pass `-R <group>/<project>`: there is no git access inside the sandbox, so the repository cannot be inferred.
      - Each call asks the user for approval.
      - Subagents have no memory of this: when you brief `dev`, `architect` or `qa` on GitLab content, paste what they need instead of telling them to fetch it.
    '';
  };
}
