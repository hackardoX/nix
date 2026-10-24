{ config, inputs, ... }:
{
  flake.meta.users.root = {
    email = config.flake.meta.users.hackardo.email;
    description = "System administrator";
    name = "root";
    uid = 0;
  };

  flake.modules.nixos.root = nixosArgs: {
    sops.secrets."root/hashed_password" = {
      sopsFile = "${inputs.self}/secrets/users/root.yaml";
      neededForUsers = true;
    };

    users.users.${config.flake.meta.users.root.name} = {
      inherit (config.flake.meta.users.root) description uid;
      isNormalUser = false;
      hashedPasswordFile = nixosArgs.config.sops.secrets."root/hashed_password".path;
    };
  };
}
