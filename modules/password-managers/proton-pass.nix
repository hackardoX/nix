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
        packages = [ pkgs.proton-pass ];
        sessionVariables = {
          SSH_AUTH_SOCK = protonPassAgentSocketPath;
        };
      };
      services.proton-pass-agent.enable = true;
      ssh.extraConfig = ''
        IdentityAgent "${protonPassAgentSocketPath}"
      '';
      programs.git.signing.signer = "${pkgs.openssh}/bin/ssh-keygen";
    };
}
