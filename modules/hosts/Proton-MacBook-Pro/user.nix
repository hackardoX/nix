{ config, ... }:
{
  configurations.darwin.Proton-MacBook-Pro.module = {
    system.primaryUser = config.flake.meta.users.aaccardo.name;
  };
}
