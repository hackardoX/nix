{
  flake.modules.homeManager.git = hmArgs: {
    config = {
      sops.secrets."gitlab/host" = { };
      sops.secrets."gitlab/name" = { };
      sops.secrets."gitlab/email" = { };
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
      programs.ssh.includes = [ hmArgs.config.sops.templates."forge-gitlab-config".path ];
      programs.git.includes = [
        {
          condition = "hasconfig:remote.*.url:git@gitlab.com:*/**";
          path = hmArgs.config.sops.templates."git-gitlab-identity".path;
        }
        {
          condition = "hasconfig:remote.*.url:https://gitlab.com/**";
          path = hmArgs.config.sops.templates."git-gitlab-identity".path;
        }
        {
          condition = "hasconfig:remote.*.url:ssh://git@gitlab.com:*/**";
          path = hmArgs.config.sops.templates."git-gitlab-identity".path;
        }
      ];
    };
  };
}
