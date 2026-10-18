{ config, inputs, ... }:
{
  configurations.darwin.Andrea-MacBook-Air.module = {
    sops.defaultSopsFile = "${inputs.self}/secrets/hosts/Andrea-MacBook-Air/secrets.yaml";
    sops.secrets = {
      "ssh/andrea_mac_book_air.pub" = {
        path = "/Users/${config.flake.meta.users.hackardo.name}/.ssh/andrea_mac_book_air.pub";
        owner = config.flake.meta.users.hackardo.name;
        group = "staff";
        mode = "0644";
      };
      "ssh/andrea_mac_book_air" = {
        path = "/Users/${config.flake.meta.users.hackardo.name}/.ssh/andrea_mac_book_air";
        owner = config.flake.meta.users.hackardo.name;
        group = "admin";
        mode = "0600";
      };
      "ssh/homelab.pub" = {
        path = "/Users/${config.flake.meta.users.hackardo.name}/.ssh/homelab.pub";
        owner = config.flake.meta.users.hackardo.name;
        group = "staff";
        mode = "0644";
      };
      "ssh/homelab_initrd.pub" = {
        path = "/Users/${config.flake.meta.users.hackardo.name}/.ssh/homelab_initrd.pub";
        owner = config.flake.meta.users.hackardo.name;
        group = "staff";
        mode = "0644";
      };
    };
  };
}
