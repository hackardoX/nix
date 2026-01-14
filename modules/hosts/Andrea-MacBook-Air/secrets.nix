{
  configurations.darwin.Andrea-MacBook-Air.module =
    { config, ... }:
    {
      home-manager.users.${config.system.primaryUser}.programs.onepassword-secrets.secrets = {
        hetznerCloudPublicKey = {
          path = ".ssh/hetzner_cloud_debian.8gb.hel1.1.pub";
          reference = "op://Development/Hetzner Cloud debian-8gb-hel1-1/public key";
          group = "staff";
        };
        hetznerHomeLabPublicKey = {
          path = ".ssh/hetzner_homelab.pub";
          reference = "op://Development/Hetzner HomeLab/public key";
          group = "staff";
        };
        andreaMacBookAirPublicKey = {
          path = ".ssh/Andrea-MacBook-Air.pub";
          reference = "op://Development/Andrea-MacBook-Air/public key";
          group = "staff";
        };
        andreaMacBookAirPrivateKey = {
          path = ".ssh/Andrea-MacBook-Air";
          reference = "op://Development/Andrea-MacBook-Air/private key";
          group = "staff";
        };
      };
    };
}
