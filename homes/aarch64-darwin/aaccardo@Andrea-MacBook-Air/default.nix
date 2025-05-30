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
        enable = false;
        secrets = [
          {
            path = ".ssh/github.pub";
            reference = "op://Development/Github Authorisation/public key";
          }
          {
            path = ".ssh/git_signature.pub";
            reference = "op://Development/Github Signature/public key";
          }
        ];
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
