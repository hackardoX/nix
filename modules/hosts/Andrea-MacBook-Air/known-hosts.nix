{ config, ... }:
{
  configurations.darwin.Andrea-MacBook-Air.module = {
    home-manager.users.${config.flake.meta.users.hackardo.name} = hmArgs: {
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
      };
    };
  };
}
