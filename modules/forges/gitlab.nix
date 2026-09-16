{
  flake.modules.homeManager.gitlab = hmArgs: {
    config = {
      sops.secrets."gitlab/host" = { };
      sops.secrets."gitlab/name" = { };
      sops.secrets."gitlab/email" = { };
      sops.secrets."gitlab/token" = { };
      sops.secrets."gitlab/authorization_key" = {
        path = "${hmArgs.config.home.homeDirectory}/.ssh/gitlab_authorisation.pub";
        mode = "0644";
      };
      sops.templates."forge-gitlab-config".content = ''
        Host ${hmArgs.config.sops.placeholder."gitlab/host"}
            HostName ${hmArgs.config.sops.placeholder."gitlab/host"}
            ForwardAgent no
            IdentityFile ${hmArgs.config.sops.secrets."gitlab/authorization_key".path}
            IdentitiesOnly yes
      '';
      sops.templates."git-gitlab-identity".content = ''
        [user]
            name = ${hmArgs.config.sops.placeholder."gitlab/name"}
            email = ${hmArgs.config.sops.placeholder."gitlab/email"}
      '';
      sops.templates."git-gitlab-conditional-includes".content = ''
        [includeIf "hasconfig:remote.*.url:git@${hmArgs.config.sops.placeholder."gitlab/host"}:*/**"]
            path = ${hmArgs.config.sops.templates."git-gitlab-identity".path}
        [includeIf "hasconfig:remote.*.url:https://${hmArgs.config.sops.placeholder."gitlab/host"}/**"]
            path = ${hmArgs.config.sops.templates."git-gitlab-identity".path}
        [includeIf "hasconfig:remote.*.url:ssh://git@${hmArgs.config.sops.placeholder."gitlab/host"}:*/**"]
            path = ${hmArgs.config.sops.templates."git-gitlab-identity".path}
      '';
      programs.ssh.includes = [ hmArgs.config.sops.templates."forge-gitlab-config".path ];
      programs.git.includes = [
        { path = hmArgs.config.sops.templates."git-gitlab-conditional-includes".path; }
      ];

      home.sessionVariables = {
        GITLAB_TOKEN = "$(cat ${hmArgs.config.sops.secrets."gitlab/token".path})";
        GITLAB_HOST = "$(cat ${hmArgs.config.sops.secrets."gitlab/host".path})";
      };
    };
  };
}
