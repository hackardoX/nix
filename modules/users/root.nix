{ config, ... }:
{
  flake.meta.users.root = {
    email = config.flake.lib.fromBase64 "aGFja2FyZG9AZ21haWwuY29t";
    description = "System administrator";
    name = "root";
    uid = 0;
  };

  flake.modules.nixos.root = nixosArgs: {
    sops.secrets."root/hashed_password" = {
      sopsFile = ../../secrets/users/root.yaml;
      neededForUsers = true;
    };

    users.users.${config.flake.meta.users.root.name} = {
      inherit (config.flake.meta.users.root) description uid;
      isNormalUser = false;
      hashedPasswordFile = nixosArgs.config.sops.secrets."root/hashed_password".path;
    };
  };
}
