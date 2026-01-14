{ config, lib, ... }:
{
  configurations.nixos.Hetzner-HomeLab.module = {
    system.primaryUser = lib.mkForce config.flake.meta.users.hetzner.name;
  };
}
