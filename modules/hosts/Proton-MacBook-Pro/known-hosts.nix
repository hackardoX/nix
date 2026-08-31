{ config, ... }:
{
  configurations.darwin.Proton-MacBook-Pro.module = {
    home-manager.users.${config.flake.meta.users.aaccardo.name} = {
      ssh.extraHosts = {
      };
    };
  };
}
