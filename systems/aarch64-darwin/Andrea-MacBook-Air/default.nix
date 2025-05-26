{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.user;
in
{
  aaccardo = {
    security = {
      sudo = enabled;
      sops = {
        enable = false;
        sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        defaultSopsFile = lib.snowfall.fs.get-file "secrets/${cfg.name}/default.yaml";
      };
    };

    suites = {
      common = enabled;
      development = enabled;
      networking = enabled;
    };

    tools = {
      homebrew = enabled;
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
