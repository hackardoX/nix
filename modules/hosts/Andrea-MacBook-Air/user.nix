{ lib, ... }:
{
  configurations.darwin.Andrea-MacBook-Air.module = {
    system.primaryUser = lib.mkForce "aaccardo"; # config.flake.meta.hackardo.name;
  };
}
