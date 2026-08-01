{ config, ... }:
{
  configurations.darwin.Andrea-MacBook-Air.module = {
    home-manager.users.${config.flake.meta.users.aaccardo.name} =
      hmArgs@{ pkgs, ... }:
      {
        ssh.extraHosts = {
          "hetzner-cloud" = {
            hostname = "46.62.149.89";
            user = "aaccardo";
            identityFile = hmArgs.config.programs.onepassword-secrets.secretPaths.hetznerCloudPublicKey;
            port = 22;
          };
          "hetzner-homelab" = {
            hostname = "135.181.200.250";
            user = config.flake.meta.users.hetzner.name;
            identityFile = hmArgs.config.programs.onepassword-secrets.secretPaths.hetznerHomeLabPublicKey;
            port = 22;
          };
          "homelab" = {
            hostname = "${config.flake.nixosConfigurations.HomeLab.config.networking.hostName}.local";
            user = config.flake.meta.users.hal.name;
            identityFile = hmArgs.config.programs.onepassword-secrets.secretPaths.homeLabPublicKey;
            port = 22;
            forwardAgent = true;
          };
          "homelab-initrd" = {
            hostname = "192.168.1.55";
            user = "root";
            identityFile = hmArgs.config.programs.onepassword-secrets.secretPaths.homeLabInitrdPublicKey;
            port = 2222;
            requestTTY = true;
            remoteCommand = "systemd-tty-ask-password-agent";
          };
          "ssh.homelab4.fun" = {
            hostname = "ssh.homelab4.fun";
            user = config.flake.meta.users.hal.name;
            identityFile = hmArgs.config.programs.onepassword-secrets.secretPaths.homeLabPublicKey;
            proxyCommand = "${pkgs.cloudflared}/bin/cloudflared access ssh --hostname %h";
            forwardAgent = true;
          };
        };
      };
  };
}
