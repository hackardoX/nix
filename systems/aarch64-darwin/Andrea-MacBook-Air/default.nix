{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) enabled;
  cfg = config.${namespace}.user;
  suites = import (lib.snowfall.fs.get-file "shared/profiles/Andrea-MacBook-Air/default.nix") {
    inherit config lib namespace;
  };
in
{
  aaccardo = {
    inherit (suites) suites;

    security = {
      sudo = enabled;
      # sops = {
      #   enable = false;
      #   sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      #   defaultSopsFile = lib.snowfall.fs.get-file "secrets/${cfg.name}/default.yaml";
      # };
    };
  };

  networking = {
    computerName = "Andrea's MacBook Air";
    hostName = "Andrea-MacBook-Air";
    localHostName = "Andrea-MacBook-Air.local";

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

  users.users.${cfg.name} = {
    openssh = {
      authorizedKeys.keys = [ ];
    };
  };

  system = {
    primaryUser = cfg.name;
    stateVersion = 5;
  };
}
