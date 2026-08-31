let
  user = "deploy";
in
{
  flake = {
    meta.users.deploy.name = "deploy";
    modules.nixos.deploy = {
      users.users.${user} = {
        isNormalUser = true;
        description = "System deploy user";
        uid = 2000;
        extraGroups = [
          "wheel"
        ];
        openssh.authorizedKeys.keys = [
          # TODO: add your public key here
          "ssh-ed25519 ... ${user}"
        ];
      };

      nix.settings.trusted-users = [ user ];
    };
  };
}
