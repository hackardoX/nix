{ config, ... }:
{
  configurations.nixos.Hetzner-HomeLab.module = {
    services.onepassword-secrets.secrets = {
      hetznerHostPrivateKey = {
        path = "/etc/secrets/initrd/ssh_host_key";
        reference = "op://Development/Hetzner HomeLab Host Key/private key";
        group = "staff";
      };
      hetznerHostPublicKey = {
        path = "/etc/secrets/initrd/ssh_host_key.pub";
        reference = "op://Development/Hetzner HomeLab Host Key/public key";
        group = "staff";
      };
    };

    home-manager.users.${config.flake.meta.users.hetzner.name}.programs.onepassword-secrets.secrets = {
      hetznerUserPassword = {
        path = ".secrets/.password";
        reference = "op://Development/Hetzner HomeLab/user password";
        group = "staff";
      };
    };
  };
}
