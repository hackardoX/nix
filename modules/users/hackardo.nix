{ config, ... }:
{
  flake.meta.users.hackardo = {
    email = config.flake.lib.fromBase64 "aGFja2FyZG9AZ21haWwuY29t";
    description = "Andrea Accardo";
    name = "hackardo";
    uid = 501;
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICyyfmn+7pOkf7UXgWV6BzceLpJk49AT07XgCnnbd323 hackardo"
    ];
  };

  flake.modules.darwin.hackardo =
    { pkgs, ... }:
    {
      imports = [ config.flake.modules.darwin.rclone ];

      nix.settings.allowed-users = [ config.flake.meta.users.hackardo.name ];

      users.users.${config.flake.meta.users.hackardo.name} = {
        inherit (config.flake.meta.users.hackardo)
          description
          name
          uid
          ;
        home = "/Users/${config.flake.meta.users.hackardo.name}";
        shell = pkgs.zsh;
      };
      users.groups.onepassword-secrets.members = [ config.flake.meta.users.hackardo.name ];
    };

  flake.modules.homeManager.hackardo = {
    imports = with config.flake.modules.homeManager; [
      config.flake.modules.homeManager."1password"
      base
      dev
      file-sync
      media
      shell
      theme
    ];
    services.rclone.remotes = [
      "koofr"
      "gdrive"
    ];
    home.username = config.flake.meta.users.hackardo.name;
    home.stateVersion = "24.11";
  };
}
