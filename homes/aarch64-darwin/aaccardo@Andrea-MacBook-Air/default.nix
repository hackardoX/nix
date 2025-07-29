{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) enabled;
  suites = import (lib.snowfall.fs.get-file "shared/profiles/Andrea-MacBook-Air/default.nix") {
    inherit config lib namespace;
  };
in
{
  aaccardo = {
    inherit (suites) suites;

    user = {
      enable = true;
      inherit (config.snowfallorg.user) name;
    };

    security = {
      opnix = {
        enable = true;
        secrets = {
          gitAuthorisation = {
            path = ".ssh/github_authorisation.pub";
            reference = "op://Development/Github Authorisation/public key";
            group = "staff";
          };
          gitSignature = {
            path = ".ssh/git_signature.pub";
            reference = "op://Development/Git Signature/public key";
            group = "staff";
          };
          oracleCloudKey = {
            path = ".ssh/oracle_cloud_a1-flex.4ocpu.24gb.pub";
            reference = "op://Development/Oracle Cloud a1-flex.4ocpu.24gb/public key";
            group = "staff";
          };
          andreaMacBookAirPublicKey = {
            path = ".ssh/Andrea-MacBook-Air.pub";
            reference = "op://Development/Andrea-MacBook-Air/public key";
            group = "staff";
          };
          andreaMacBookAirPrivateKey = {
            path = ".ssh/Andrea-MacBook-Air";
            reference = "op://Development/Andrea-MacBook-Air/private key";
            group = "staff";
          };
        };
      };
    };

    # services = {
    #   sops = {
    #     enable = false;
    #     defaultSopsFile = lib.snowfall.fs.get-file "secrets/${cfg.name}/default.yaml";
    #     sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
    #   };
    # };

    theme.catppuccin = enabled;
  };

  home.stateVersion = "24.11";
}
