{
  configurations.darwin.Proton-MacBook-Pro.module = {
    networking = {
      computerName = "Proton MacBook Pro";
      hostName = "Proton-MacBook-Pro";
      localHostName = "Proton-MacBook-Pro";

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
