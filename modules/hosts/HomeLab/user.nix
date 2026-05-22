{ config, ... }:
{
  configurations.nixos.HomeLab.module = {
    system.primaryUser = config.flake.meta.users.hal.name;
  };
}
