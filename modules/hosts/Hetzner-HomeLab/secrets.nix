{
  configurations.nixos.Hetzner-HomeLab.module = {
    services.onepassword-secrets.secrets = {
      hetznerHomeLabPrivateKey = {
        path = "/etc/ssh/ssh_host_ed25519_key";
        reference = "op://Development/Hetzner HomeLab/private key";
        group = "staff";
      };
      hetznerHomeLabPublicKey = {
        path = "/etc/ssh/ssh_host_ed25519_key.pub";
        reference = "op://Development/Hetzner HomeLab/public key";
        group = "staff";
      };
    };
  };
}
