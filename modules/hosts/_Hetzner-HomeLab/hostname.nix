{
  configurations.nixos.Hetzner-HomeLab.module = {
    networking = {
      hostName = "Hetzner-HomeLab";
      useDHCP = false;
      dhcpcd.enable = false;
      interfaces.enp1s0.useDHCP = true;
      nameservers = [
        "185.12.64.2" # Hetzner primary DNS
        "185.12.64.1" # Hetzner secondary DNS
      ];
    };
  };
}
