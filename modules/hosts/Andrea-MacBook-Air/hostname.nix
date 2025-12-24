{
  configurations.darwin.Andrea-MacBook-Air.module = {
    networking = {
      computerName = "Andrea's MacBook Air";
      hostName = "Andrea-MacBook-Air";
      localHostName = "Andrea-MacBook-Air";

      knownNetworkServices = [
        "Wi-Fi"
        "Thunderbolt Bridge"
      ];

      wakeOnLan.enable = true;
    };
  };
}
