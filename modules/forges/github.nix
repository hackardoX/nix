let
  sshSettings = {
    # https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
    programs.ssh.knownHosts."github.com".publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
  };
in
{
  flake.modules.nixos.base = sshSettings;
  flake.modules.darwin.base = sshSettings;
  flake.modules.homeManager.dev = hmArgs: {
    config = {
      ssh.extraHosts = {
        "github.com" = {
          hostname = "github.com";
          forwardAgent = false;
          identityFile = hmArgs.config.programs.onepassword-secrets.secretPaths.githubAuthorisationPublicKey;
          identitiesOnly = true;
        };
      };
    };
  };
}
