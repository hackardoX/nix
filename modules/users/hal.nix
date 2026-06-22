{ config, ... }:
{
  flake.meta.users.hal = {
    email = config.flake.lib.fromBase64 "aGFja2FyZG9AZ21haWwuY29t";
    description = "HAL 9000";
    name = "hal";
    uid = 502;
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOa3X9sTqDrEddYn5qxluMw6h5SzA5eC9UMnIDQNYCiV"
    ];
  };

  flake.modules.nixos.hal =
    nixosArgs@{ pkgs, ... }:
    {
      users.users.${config.flake.meta.users.hal.name} = {
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

      environment.etc."ssh/authorized_sudo_keys/${config.flake.meta.users.hal.name}" = {
        text = ''
          ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOa3X9sTqDrEddYn5qxluMw6h5SzA5eC9UMnIDQNYCiV
        '';
        mode = "0644";
        user = "root";
        group = "root";
      };

      services = {
        openssh.settings.AllowUsers = [ config.flake.meta.users.hal.name ];
        onepassword-secrets.secrets = {
          halHashedUserPassword = {
            path = "/run/secrets/.hal_password";
            reference = "op://HomeLab/Hal/hashed user password";
            group = "wheel";
          };
        };
      };
    };
}
