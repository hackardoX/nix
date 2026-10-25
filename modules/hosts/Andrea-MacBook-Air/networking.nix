{ config, ... }:
{
  configurations.darwin.Andrea-MacBook-Air.module = {
    networking = {
      computerName = "Andrea's MacBook Air";
      hostName = config.flake.meta.hosts.Andrea-MacBook-Air.hostName;
      localHostName = config.flake.meta.hosts.Andrea-MacBook-Air.hostName;
      knownNetworkServices = [
        "Wi-Fi"
        "Thunderbolt Bridge"
      ];
      wakeOnLan.enable = true;
      applicationFirewall = {
        enableStealthMode = true;
        blockAllIncoming = true;
      };
    };
  };
}
