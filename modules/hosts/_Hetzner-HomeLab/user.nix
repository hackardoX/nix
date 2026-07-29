{ config, ... }:
{
  configurations.nixos.Hetzner-HomeLab.module = {
    system.primaryUser = config.flake.meta.users.hetzner.name;
  };
}
