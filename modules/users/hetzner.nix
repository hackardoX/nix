{ config, ... }:
{
  flake = {
    meta.users.hetzner = {
      email = config.flake.lib.fromBase64 "aGFja2FyZG9AZ21haWwuY29t";
      description = "Hetzner HomeLab";
      name = "hetzner-homelab";
      uid = 501;
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICyyfmn+7pOkf7UXgWV6BzceLpJk49AT07XgCnnbd323"
      ];
    };

    modules = {
      nixos.hetzner =
        { pkgs, ... }:
        {
          users = {
            mutableUsers = false;
            users = {
              hetzner = {
                inherit (config.flake.meta.users.hetzner) description;
                isNormalUser = true;
                shell = pkgs.zsh;
                hashedPasswordFile = config.programs.onepassword-secrets.secretPaths.hetznerUserPasswor or null;
                extraGroups = [
                  "wheel"
                ];
                openssh.authorizedKeys.keys = config.flake.meta.users.hetzner.authorizedKeys;
              };
            };
          };
        };
    };
  };
}
