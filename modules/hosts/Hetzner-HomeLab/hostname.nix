{
  configurations.nixos.Hetzner-HomeLab.module = {
    networking = {
      computerName = "Hetzner-HomeLab";
      hostName = "Hetzner-HomeLab";
      localHostName = "Hetzner-HomeLab";

      networkmanager.enable = true;
      useDHCP = true;
    };
  };
}
