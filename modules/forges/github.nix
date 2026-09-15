{
  flake.modules.homeManager.github = hmArgs: {
    config = {
      sops.secrets."github/host" = { };
      sops.secrets."github/name" = { };
      sops.secrets."github/email" = { };
      sops.secrets."github/authorization_key" = {
        path = "${hmArgs.config.home.homeDirectory}/.ssh/github_authorisation.pub";
        mode = "0644";
      };
      sops.templates."forge-github-config".content = ''
        Host ${hmArgs.config.sops.placeholder."github/host"}
            HostName ${hmArgs.config.sops.placeholder."github/host"}
            ForwardAgent no
            IdentityFile ${hmArgs.config.sops.secrets."github/authorization_key".path}
            IdentitiesOnly yes
      '';
      sops.templates."git-github-identity".content = ''
        [user]
            name = ${hmArgs.config.sops.placeholder."github/name"}
            email = ${hmArgs.config.sops.placeholder."github/email"}
      '';
      sops.templates."git-github-conditional-includes".content = ''
        [includeIf "hasconfig:remote.*.url:git@${hmArgs.config.sops.placeholder."github/host"}:*/**"]
            path = ${hmArgs.config.sops.templates."git-github-identity".path}
        [includeIf "hasconfig:remote.*.url:https://${hmArgs.config.sops.placeholder."github/host"}/**"]
            path = ${hmArgs.config.sops.templates."git-github-identity".path}
        [includeIf "hasconfig:remote.*.url:ssh://git@${hmArgs.config.sops.placeholder."github/host"}:*/**"]
            path = ${hmArgs.config.sops.templates."git-github-identity".path}
      '';
      programs.ssh.includes = [ hmArgs.config.sops.templates."forge-github-config".path ];
      programs.git.includes = [
        { path = hmArgs.config.sops.templates."git-github-conditional-includes".path; }
      ];
    };
  };
}
