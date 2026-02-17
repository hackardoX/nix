{ config, ... }:
{
  configurations.nixos.Hetzner-HomeLab = {
    deploy = {
      hostname = "hetzner-homelab";
      sshUser = config.flake.meta.users.hetzner.name;
      remoteBuild = true;
      interactiveSudo = true;
      user = "root";
    };
  };
}
