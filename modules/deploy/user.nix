{ config, lib, ... }:
let
  user = "deploy";
in
{
  flake = {
    meta.users.deploy.name = "deploy";
    modules.nixos.homelab = nixosArgs: {
      users.users.${user} = {
        isNormalUser = true;
        description = "System deploy user";
        uid = 2000;
        extraGroups = [
          "wheel"
          "sudo"
        ];
        openssh.authorizedKeys.keys =
          config.flake.meta.users.${nixosArgs.config.system.primaryUser}.authorizedKeys;
      };

      services.openssh.settings.AllowUsers = lib.mkMerge [ user ];

      security = {
        pam.sshAgentAuth = {
          enable = true;
        };
      };

      nix.settings.trusted-users = [ user ];
    };
  };
}
