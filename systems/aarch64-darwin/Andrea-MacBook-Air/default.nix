{
  config,
  inputs,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) enabled;
  cfg = config.${namespace}.user;
  suites = import (lib.snowfall.fs.get-file "shared/profiles/Andrea-MacBook-Air/default.nix") {
    inherit
      config
      inputs
      lib
      namespace
      ;
  };
in
{
  aaccardo = {
    inherit (suites) suites;

    security = {
      sudo = enabled;
    };

  };

  services.onepassword-secrets = {
    enable = true;
    tokenFile = "/etc/opnix-token";
    users = [ cfg.name ];
    secrets = {
      andreaMacBookAirPublicKey = {
        path = "/etc/ssh/Andrea-MacBook-Air.pub";
        reference = "op://Development/Andrea-MacBook-Air/public key";
        owner = cfg.name;
        group = "staff";
        mode = "0644";
      };
      andreaMacBookAirPrivateKey = {
        path = "/etc/ssh/Andrea-MacBook-Air";
        reference = "op://Development/Andrea-MacBook-Air/private key";
        owner = cfg.name;
        group = "staff";
      };
    };
  };

  networking = {
    computerName = "Andrea's MacBook Air";
    hostName = "Andrea-MacBook-Air";
    localHostName = "Andrea-MacBook-Air";

    knownNetworkServices = [
      "Wi-Fi"
      "Thunderbolt Bridge"
    ];

    wakeOnLan = enabled;
  };

  nix.settings = {
    cores = 8;
    max-jobs = 3;
  };

  system = {
    primaryUser = cfg.name;
    stateVersion = 5;
  };
}
