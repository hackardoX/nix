{ config, ... }:
{
  flake.meta.users.hal = {
    email = config.flake.lib.fromBase64 "aGFja2FyZG9AZ21haWwuY29t";
    description = "HAL 9000";
    name = "hal";
    uid = 9000;
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOa3X9sTqDrEddYn5qxluMw6h5SzA5eC9UMnIDQNYCiV"
    ];
  };

  flake.modules.nixos.hal =
    { pkgs, ... }:
    {
      users.users.${config.flake.meta.users.hal.name} = {
        inherit (config.flake.meta.users.hal) description uid;
        isNormalUser = true;
        shell = pkgs.zsh;
        hashedPasswordFile = "$y$j9T$Sv8i2SE20JnZzX1irLZ4k1$1o3LWQVdeQDfp9z6U1ZnN1uaoYvQsb21HF8xsTTxDp2";
        extraGroups = [
          "wheel"
          "onepassword-secrets"
        ];
        openssh.authorizedKeys.keys = config.flake.meta.users.hal.authorizedKeys;
      };
    };
}
