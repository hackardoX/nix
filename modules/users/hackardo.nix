{ config, ... }:
{
  flake.meta.users.hackardo = {
    email = config.flake.lib.fromBase64 "aGFja2FyZG9AZ21haWwuY29t";
    description = "Andrea Accardo";
    name = "aaccardo";
    uid = 501;
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICyyfmn+7pOkf7UXgWV6BzceLpJk49AT07XgCnnbd323"
    ];
  };

  flake.modules.darwin.hackardo =
    { pkgs, ... }:
    {
      users.users.${config.flake.meta.users.hackardo.name} = {
        inherit (config.flake.meta.users.hackardo)
          description
          name
          uid
          ;
        home = "/Users/${config.flake.meta.users.hackardo.name}";
        shell = pkgs.zsh;
      };
    };
}
