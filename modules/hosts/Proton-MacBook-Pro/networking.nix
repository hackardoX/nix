{ config, ... }:
{
  configurations.darwin.Proton-MacBook-Pro.module = {
    networking = {
      computerName = "Proton MacBook Pro";
      hostName = config.flake.meta.hosts.Proton-MacBook-Pro.hostName;
      localHostName = config.flake.meta.hosts.Proton-MacBook-Pro.hostName;

      knownNetworkServices = [
        "Wi-Fi"
        "Thunderbolt Bridge"
      ];

      wakeOnLan.enable = true;

      dns = [ ];

      applicationFirewall = {
        enableStealthMode = true;
        blockAllIncoming = true;
      };
    };
  };
}
