{ config, ... }:
{
  configurations.darwin.Andrea-MacBook-Air.module = {
    system.primaryUser = config.flake.meta.users.hackardo.name;
  };
}
