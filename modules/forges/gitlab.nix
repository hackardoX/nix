{ config, ... }:
let
  host = config.flake.lib.fromBase64 "Z2l0bGFiLnByb3RvbnRlY2guY2gK";
  sshSettings = {
    programs.ssh.knownHosts.${host}.publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA4HeZAbgzn1cQNXg7M0a6+VqP4WCnG6X6O63rZRNtBR";
  };
in
{
  flake.modules.nixos.base = sshSettings;
  flake.modules.darwin.base = sshSettings;
  flake.modules.homeManager.dev = hmArgs: {
    config = {
      ssh.extraHosts = {
        ${host} = {
          hostname = host;
          forwardAgent = false;
          identityFile = "${hmArgs.config.home.homeDirectory}/.ssh/gitlab_authorisation.pub";
          identitiesOnly = true;
        };
      };
    };
  };
}
