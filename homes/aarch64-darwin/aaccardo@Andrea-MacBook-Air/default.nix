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
          hetznerCloudKey = {
            path = ".ssh/hetzner_cloud_debian.8gb.hel1.1.pub";
            reference = "op://Development/Hetzner Cloud debian-8gb-hel1-1/public key";
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
