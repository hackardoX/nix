{ config, ... }:
{
  flake.meta.hosts.HomeLab = {
    hostName = "HomeLab";
    user = config.flake.meta.users.hal.name;
  };
}
