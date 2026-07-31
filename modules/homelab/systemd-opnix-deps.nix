{ config, lib, ... }:
let
  homelabUsers = lib.filterAttrs (
    name: u: builtins.elem "homelab-users" u.extraGroups && config.home-manager.users ? ${name}
  ) config.users.users;
in
{
  flake.modules.nixos.homelab = {
    systemd.services =
      (lib.mapAttrs' (
        _: u:
        lib.nameValuePair "user@${toString u.uid}" {
          after = [ "opnix-secrets.service" ];
          wants = [ "opnix-secrets.service" ];
          overrideStrategy = "asDropin";
        }
      ) homelabUsers)
      // (lib.mapAttrs' (
        name: u:
        lib.nameValuePair "home-manager-${name}" {
          after = [ "user@${toString u.uid}.service" ];
          wants = [ "user@${toString u.uid}.service" ];
        }
      ) homelabUsers);
  };
}
