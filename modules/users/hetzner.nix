{ config, ... }:
{
  flake = {
    meta.users.hetzner = {
      email = config.flake.lib.fromBase64 "aGFja2FyZG9AZ21haWwuY29t";
      description = "Hetzner HomeLab";
      name = "hetzner";
      uid = 501;
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKjfrZIUY652nVzjjhhhukZoU3RCdws951XOb1PKEWJu"
      ];
    };

    modules = {
      nixos.hetzner =
        nixosArgs@{ pkgs, ... }:
        {
          users = {
            mutableUsers = false;
            users = {
              ${config.flake.meta.users.hetzner.name} = {
                inherit (config.flake.meta.users.hetzner) description;
                isNormalUser = true;
                shell = pkgs.zsh;
                hashedPasswordFile =
                  nixosArgs.config.services.onepassword-secrets.secretPaths.hetznerHashedUserPassword;
                extraGroups = [
                  "wheel"
                ];
                openssh.authorizedKeys.keys = config.flake.meta.users.hetzner.authorizedKeys;
              };

              root.hashedPassword = "!";
            };
          };
          services.onepassword-secrets.secrets = {
            hetznerHashedUserPassword = {
              path = "/etc/.secrets/.hetzner_password";
              reference = "op://Development/Hetzner HomeLab/hashed user password";
              group = "staff";
            };
          };
        };
    };
  };
}
