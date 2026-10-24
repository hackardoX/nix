{ config, ... }:
{
  flake = {
    meta.users.deploy = {
      name = "deploy";
      uid = 2000;
    };
    modules.nixos.deploy = {
      users.users.${config.flake.meta.users.deploy.name} = {
        isNormalUser = true;
        description = "System deploy user";
        uid = config.flake.meta.users.deploy.uid;
        extraGroups = [
          "wheel"
        ];
        openssh.authorizedKeys.keys = [
          # TODO: add your public key here
          "ssh-ed25519 ... ${config.flake.meta.users.deploy.name}"
        ];
      };

      nix.settings.trusted-users = [ config.flake.meta.users.deploy.name ];
    };
  };
}
