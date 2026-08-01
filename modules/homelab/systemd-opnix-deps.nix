{ lib, ... }:
{
  flake.modules.nixos.homelab =
    nixosArgs:
    let
      homelabUsers = lib.filterAttrs (
        name: u:
        builtins.elem "homelab-users" u.extraGroups && nixosArgs.config.home-manager.users ? ${name}
      ) nixosArgs.config.users.users;
    in
    {
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
            overrideStrategy = "asDropin";
          }
        ) homelabUsers);
    };
}
