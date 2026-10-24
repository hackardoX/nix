{ config, inputs, ... }:
{
  flake.meta.users.hetzner = {
    email = config.flake.meta.users.hackardo.email;
    description = "Hetzner HomeLab";
    name = "hetzner";
    uid = 1001;
  };

  flake.modules.nixos.hetzner =
    nixosArgs@{ pkgs, ... }:
    {
      sops.secrets."hetzner/hashed_password" = {
        sopsFile = "${inputs.self}/secrets/users/hetzner.yaml";
        neededForUsers = true;
      };
      sops.secrets."hetzner/authorized_key" = {
        sopsFile = "${inputs.self}/secrets/users/hetzner.yaml";
      };

      users.users.${config.flake.meta.users.hetzner.name} = {
        inherit (config.flake.meta.users.hetzner) description uid;
        isNormalUser = true;
        group = config.flake.meta.users.hetzner.primaryGroup;
        shell = pkgs.zsh;
        hashedPasswordFile = nixosArgs.config.sops.secrets."hetzner/hashed_password".path;
        extraGroups = [ "wheel" ];
      };

      users.groups.${config.flake.meta.users.hetzner.primaryGroup} = {
        gid = config.flake.meta.users.hetzner.uid;
      };
    };

  flake.modules.homeManager.hetzner = {
    imports = with config.flake.modules.homeManager; [
      base
      sops
    ];
    sops.defaultSopsFile = "${inputs.self}/secrets/users/hetzner.yaml";
    home.username = config.flake.meta.users.hetzner.name;
    home.stateVersion = "26.05";
  };
}
