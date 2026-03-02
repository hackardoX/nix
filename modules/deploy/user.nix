let
  user = "deploy";
in
{ config, ... }:
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

      services.openssh.settings.AllowUsers = [ user ];

      security = {
        pam.sshAgentAuth = {
          enable = true;
        };
        sudo.extraRules = [
          {
            users = [ user ];
            commands = [
              { command = "/nix/store/*-activatable-nixos-system-*/activate-rs"; }
              { command = "/run/current-system/sw/bin/rm /tmp/deploy-rs-canary-*"; }
            ];
          }
        ];
      };

      nix.settings.trusted-users = [ user ];
    };
  };
}
