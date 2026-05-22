{ config, ... }:
{
  flake = {
    meta.users.hal = {
      email = config.flake.lib.fromBase64 "aGFja2FyZG9AZ21haWwuY29t";
      description = "HAL 9000";
      name = "hal";
      uid = 502;
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOa3X9sTqDrEddYn5qxluMw6h5SzA5eC9UMnIDQNYCiV"
      ];
    };

    modules = {
      nixos.hal =
        nixosArgs@{ pkgs, ... }:
        {
          users = {
            mutableUsers = false;
            users = {
              ${config.flake.meta.users.hal.name} = {
                inherit (config.flake.meta.users.hal) description;
                isNormalUser = true;
                shell = pkgs.zsh;
                hashedPasswordFile =
                  nixosArgs.config.services.onepassword-secrets.secretPaths.halHashedUserPassword;
                extraGroups = [
                  "wheel"
                  "onepassword-secrets"
                ];
                openssh.authorizedKeys.keys = config.flake.meta.users.hal.authorizedKeys;
              };

              root.hashedPassword = "!";
            };
          };

          services = {
            openssh.settings.AllowUsers = [ config.flake.meta.users.hal.name ];
            onepassword-secrets.secrets = {
              halHashedUserPassword = {
                path = "/run/secrets/.hal_password";
                reference = "op://Development/HomeLab/hashed user password";
                group = "wheel";
              };
            };
          };
        };
    };
  };
}
