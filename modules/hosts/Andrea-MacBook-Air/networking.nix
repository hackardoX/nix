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

      dns = [
        "1.1.1.1"
        "1.0.0.1"
        "2606:4700:4700::1111"
        "2606:4700:4700::1001"
        "8.8.8.8"
        "8.8.4.4"
        "2001:4860:4860::8888"
        "2001:4860:4860::8844"
      ];

      applicationFirewall = {
        enableStealthMode = true;
        blockAllIncoming = true;
      };
    };
  };
}
