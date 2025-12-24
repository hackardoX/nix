{ config, ... }:
{
  flake = {
    meta.users.hackardo = {
      email = config.flake.lib.fromBase64 "aGFja2FyZG9AZ21haWwuY29t";
      description = "Andrea Accardo";
      name = "aaccardo";
      uid = 501;
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICyyfmn+7pOkf7UXgWV6BzceLpJk49AT07XgCnnbd323"
      ];
    };

    modules = {
      nixos.base =
        { pkgs, ... }:
        {
          users = {
            mutableUsers = false;
            users = {
              aaccardo = {
                inherit (config.flake.meta.users.hackardo) description;
                isNormalUser = true;
                shell = pkgs.zsh;
                hashedPasswordFile = config.sops.secrets.hackardo-password.path or null;
                extraGroups = [
                  "wheel"
                  "input"
                ];
                openssh.authorizedKeys.keys = config.flake.meta.users.hackardo.authorizedKeys;
              };

              root = {
                openssh.authorizedKeys.keys = config.flake.meta.users.hackardo.authorizedKeys;
              };
            };
          };
        };

      darwin.base =
        { pkgs, ... }:
        {
          users.users.aaccardo = {
            inherit (config.flake.meta.users.hackardo)
              description
              name
              uid
              ;
            shell = pkgs.zsh;
          };
        };
    };
  };
}
