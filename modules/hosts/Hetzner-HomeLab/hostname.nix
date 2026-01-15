{ lib, ... }:
{
  configurations.nixos.Hetzner-HomeLab.module = {
    networking = {
      hostName = "Hetzner-HomeLab";
      networkmanager.enable = true;
      useDHCP = lib.mkDefault true;
    };
  };
}
