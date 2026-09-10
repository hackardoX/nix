{
  flake.modules.homeManager.dev = hmArgs: {
    config = {
      sops.secrets."github/host" = { };
      sops.templates."forge-github-config".content = ''
        Host ${hmArgs.config.sops.placeholder."github/host"}
            HostName ${hmArgs.config.sops.placeholder."github/host"}
            ForwardAgent no
            IdentityFile ${hmArgs.config.home.homeDirectory}/.ssh/github_authorisation.pub
            IdentitiesOnly yes
      '';
      programs.ssh.includes = [ hmArgs.config.sops.templates."forge-github-config".path ];

    };
  };
}
