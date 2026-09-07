{ config, ... }:
{
  configurations.darwin.Andrea-MacBook-Air.module = {
    sops.defaultSopsFile = ../../../secrets/hosts/Andrea-MacBook-Air/secrets.yaml;
    sops.secrets = {
      "ssh/andrea_mac_book_air.pub" = {
        path = "/Users/${config.flake.meta.users.hackardo.name}/.ssh/andrea_mac_book_air.pub";
        group = "staff";
      };
      "ssh/andrea_mac_book_air" = {
        path = "/Users/${config.flake.meta.users.hackardo.name}/.ssh/andrea_mac_book_air";
        group = "staff";
        mode = "0600";
      };
      "ssh/homelab.pub" = {
        path = "/Users/${config.flake.meta.users.hackardo.name}/.ssh/homelab.pub";
        group = "staff";
      };
      "ssh/homelab_initrd.pub" = {
        path = "/Users/${config.flake.meta.users.hackardo.name}/.ssh/homelab_initrd.pub";
        group = "staff";
      };
    };
  };
}
