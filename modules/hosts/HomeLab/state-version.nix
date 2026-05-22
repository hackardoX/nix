{ config, ... }:
{
  configurations.nixos.HomeLab.module = {
    system.stateVersion = "26.05";
    home-manager.users.${config.flake.meta.users.hal.name}.home.stateVersion = "26.05";
  };
}
