{ config, ... }:
{
  flake.meta.users.hal = {
    email = config.flake.lib.fromBase64 "aGFja2FyZG9AZ21haWwuY29t";
    description = "HAL 9000";
    name = "hal";
    uid = 9000;
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOa3X9sTqDrEddYn5qxluMw6h5SzA5eC9UMnIDQNYCiV hal"
    ];
    sudoAuthorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG3cs+qEbW36c2nX23roMaotYZGd0Lua5pxY+BbgW5B5 hal-sudo"
    ];
  };

  flake.modules.nixos.hal =
    { pkgs, lib, ... }:
    {
      users.users.${config.flake.meta.users.hal.name} = {
        inherit (config.flake.meta.users.hal) description uid;
        isNormalUser = true;
        group = config.flake.meta.users.hal.name;
        shell = pkgs.zsh;
        hashedPassword = "$y$j9T$Sv8i2SE20JnZzX1irLZ4k1$1o3LWQVdeQDfp9z6U1ZnN1uaoYvQsb21HF8xsTTxDp2";
        extraGroups = [
          "wheel"
          "onepassword-secrets"
        ];
        openssh.authorizedKeys.keys = config.flake.meta.users.hal.authorizedKeys;
      };

      users.groups.${config.flake.meta.users.hal.name} = {
        gid = config.flake.meta.users.hal.uid;
      };

      environment.etc."ssh/authorized_sudo_keys/hal" = {
        text = lib.concatStringsSep "\n" config.flake.meta.users.hal.sudoAuthorizedKeys + "\n";
        mode = "0644";
      };
    };

  flake.modules.homeManager.hal = {
    imports = with config.flake.modules.homeManager; [ base ];
    home.username = config.flake.meta.users.hal.name;
    home.stateVersion = "26.05";
  };
}
