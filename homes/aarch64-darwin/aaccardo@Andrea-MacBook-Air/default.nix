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

    theme.catppuccin = enabled;
  };

  home.stateVersion = "24.11";
}
