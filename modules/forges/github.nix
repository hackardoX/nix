{
  flake.modules.homeManager.dev = hmArgs: {
    config = {
      sops.secrets."github/host" = { };
      sops.secrets."github/host_key" = { };
      ssh.knownHostsFiles = [ hmArgs.config.sops.templates."forge-github".path ];
      sops.templates."forge-github".content = "${hmArgs.config.sops.placeholder."github/host"} ${
        hmArgs.config.sops.placeholder."github/host_key"
      }";
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
