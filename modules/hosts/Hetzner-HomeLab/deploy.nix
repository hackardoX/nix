{ config, ... }:
{
  configurations.nixos.Hetzner-HomeLab = {
    deploy = {
      hostname = "135.181.200.250";
      sshUser = config.flake.meta.users.hetzner.name;
    };
  };
}
