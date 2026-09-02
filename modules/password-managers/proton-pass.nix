{
  flake.modules.darwin.proton-pass = {
    homebrew = {
      masApps = {
        "Proton Pass for Safari" = 6502835663;
      };
    };
  };

  flake.modules.homeManager.proton-pass =
    { config, pkgs, ... }:
    let
      protonPassAgentSocketPath =
        if pkgs.stdenv.isDarwin then
          "$(${pkgs.getconf}/bin/getconf DARWIN_USER_TEMP_DIR)/proton-pass-agent"
        else
          "${config.xdg.runtimeDir}/proton-pass-agent";
    in
    {
      home.packages = [ pkgs.proton-pass ];
      services.proton-pass-agent.enable = true;
      ssh.extraConfig = ''
        IdentityAgent ${protonPassAgentSocketPath}
      '';
      programs.git.signing.signer = "${pkgs.openssh}/bin/ssh-keygen";
    };
}
