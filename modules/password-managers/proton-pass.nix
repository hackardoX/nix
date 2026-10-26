{
  flake.modules.darwin.proton-pass = {
    homebrew = {
      masApps = {
        "Proton Pass for Safari" = 6502835663;
      };
    };
  };

  flake.modules.homeManager.proton-pass =
    hmArgs@{ pkgs, ... }:
    let
      protonPassAgentSocketPath = "${hmArgs.config.home.homeDirectory}/.ssh/proton-pass-ssh-agent.sock";
    in
    {
      home = {
        packages = [
          pkgs.proton-pass
          pkgs.proton-pass-cli
        ];
        sessionVariables = {
          SSH_AUTH_SOCK = protonPassAgentSocketPath;
        };
      };
      services.proton-pass-agent = {
        enable = true;
        # TODO: check if we still need this
        socket = "$HOME/.ssh/proton-pass-ssh-agent.sock";
      };
      ssh.extraConfig = ''
        IdentityAgent "${protonPassAgentSocketPath}"
      '';
      programs.git.signing.signer = "${pkgs.openssh}/bin/ssh-keygen";
    };
}
