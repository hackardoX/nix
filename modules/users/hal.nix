{ config, ... }:
{
  flake.meta.users.hal = {
    email = config.flake.lib.fromBase64 "aGFja2FyZG9AZ21haWwuY29t";
    description = "HAL 9000";
    name = "hal";
    uid = 9000;

    git = {
      name = "aaccardo";
      email = config.flake.lib.fromBase64 "YWFjY2FyZG9AcHJvdG9uLmNoCg==";
    };
  };

  flake.modules.nixos.hal =
    nixosArgs@{ pkgs, ... }:
    {
      sops.secrets."hal/hashed_password" = {
        sopsFile = ../../secrets/users/hal.yaml;
        neededForUsers = true;
      };
      sops.secrets."hal/authorized_key" = {
        sopsFile = ../../secrets/users/hal.yaml;
      };
      sops.secrets."hal/sudo_authorized_key" = {
        sopsFile = ../../secrets/users/hal.yaml;
      };

      nix.settings.allowed-users = [ config.flake.meta.users.hal.name ];

      users.users.${config.flake.meta.users.hal.name} = {
        inherit (config.flake.meta.users.hal) description uid;
        isNormalUser = true;
        group = config.flake.meta.users.hal.primaryGroup;
        shell = pkgs.zsh;
        hashedPasswordFile = nixosArgs.config.sops.secrets."hal/hashed_password".path;
        extraGroups = [ "wheel" ];
      };

      users.groups.${config.flake.meta.users.hal.primaryGroup} = {
        gid = config.flake.meta.users.hal.uid;
      };

      environment.etc."ssh/authorized_sudo_keys/hal".source =
        nixosArgs.config.sops.secrets."hal/sudo_authorized_key".path;
    };

  flake.modules.homeManager.hal = {
    imports = with config.flake.modules.homeManager; [
      base
      git
    ];
    sops.defaultSopsFile = ../../secrets/users/hal.yaml;
    home.username = config.flake.meta.users.hal.name;
    home.stateVersion = "26.05";
  };
}
