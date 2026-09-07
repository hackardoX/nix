{ config, ... }:
{
  configurations.darwin.Andrea-MacBook-Air.module = {
    # TODO: Move this to nixos module, refactoring ssh to allow extraHosts also for nixos/darwin module
    home-manager.users.${config.flake.meta.users.hackardo.name} =
      hmArgs@{ pkgs, ... }:
      {
        ssh.extraHosts = {
          "homelab" = {
            hostname = "${config.flake.nixosConfigurations.HomeLab.config.networking.hostName}.local";
            user = config.flake.meta.users.hal.name;
            identityFile = hmArgs.osConfig.sops.secrets."ssh/homelab.pub".path;
            port = 22;
            forwardAgent = true;
          };
          "homelab-initrd" = {
            hostname = "192.168.1.55";
            user = "root";
            identityFile = hmArgs.osConfig.sops.secrets."ssh/homelab_initrd.pub".path;
            port = 2222;
            requestTTY = true;
            remoteCommand = "systemd-tty-ask-password-agent";
          };
          "ssh.homelab4.fun" = {
            hostname = "ssh.homelab4.fun";
            user = config.flake.meta.users.hal.name;
            identityFile = hmArgs.osConfig.sops.secrets."ssh/homelab.pub".path;
            proxyCommand = "${pkgs.cloudflared}/bin/cloudflared access ssh --hostname %h";
            forwardAgent = true;
          };
        };
      };
  };
}
