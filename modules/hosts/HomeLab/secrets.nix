{
  configurations.nixos.HomeLab.module = {
    services.onepassword-secrets.secrets = {
      homeLabPrivateKey = {
        path = "/etc/ssh/ssh_host_ed25519_key";
        reference = "op://Development/HomeLab/private key";
        group = "wheel";
        services = [ "sshd" ];
      };
      homeLabPublicKey = {
        path = "/etc/ssh/ssh_host_ed25519_key.pub";
        reference = "op://Development/HomeLab/public key";
        group = "wheel";
        services = [ "sshd" ];
      };
    };
  };
}
