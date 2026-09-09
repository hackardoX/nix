{ config, ... }:
{
  flake.meta.users.hetzner = {
    email = config.flake.lib.fromBase64 "aGFja2FyZG9AZ21haWwuY29t";
    description = "Hetzner HomeLab";
    name = "hetzner";
    uid = 1001;
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKjfrZIUY652nVzjjhhhukZoU3RCdws951XOb1PKEWJu hetzner"
    ];
  };

  flake.modules.nixos.hetzner =
    nixosArgs@{ pkgs, ... }:
    {
      sops.secrets."hetzner/hashed_password" = {
        sopsFile = ../../secrets/users/hetzner.yaml;
        neededForUsers = true;
      };

      users.users.${config.flake.meta.users.hetzner.name} = {
        inherit (config.flake.meta.users.hetzner) description uid;
        isNormalUser = true;
        group = config.flake.meta.users.hetzner.primaryGroup;
        shell = pkgs.zsh;
        hashedPasswordFile = nixosArgs.config.sops.secrets."hetzner/hashed_password".path;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = config.flake.meta.users.hetzner.authorizedKeys;
      };

      users.groups.${config.flake.meta.users.hetzner.primaryGroup} = {
        gid = config.flake.meta.users.hetzner.uid;
      };
    };

  flake.modules.homeManager.hetzner = {
    imports = with config.flake.modules.homeManager; [ base ];
    sops.defaultSopsFile = ../../secrets/users/hetzner.yaml;
    home.username = config.flake.meta.users.hetzner.name;
    home.stateVersion = "26.05";
  };
}
