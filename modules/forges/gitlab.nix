{
  flake.modules.homeManager.dev = hmArgs: {
    config = {
      sops.secrets."gitlab/host" = { };
      sops.templates."forge-gitlab-config".content = ''
        Host ${hmArgs.config.sops.placeholder."gitlab/host"}
            HostName ${hmArgs.config.sops.placeholder."gitlab/host"}
            ForwardAgent no
            IdentityFile ${hmArgs.config.home.homeDirectory}/.ssh/gitlab_authorisation.pub
            IdentitiesOnly yes
      '';
      programs.ssh.includes = [ hmArgs.config.sops.templates."forge-gitlab-config".path ];
    };
  };
}
