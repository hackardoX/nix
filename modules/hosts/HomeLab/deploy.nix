{ config, ... }:
{
  configurations.nixos.HomeLab = {
    deploy = {
      hostname = config.flake.meta.reverse-proxy.hosts.ssh;
      remoteBuild = true;
      user = "root";
      sshOpts = [ "-A" ];
    };
  };
}
