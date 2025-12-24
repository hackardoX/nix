{
  configurations.homeManager.Andrea-MacBook-Air.module = {
    security = {
      opnix = {
        enable = true;
        secrets = {
          hetznerCloudKey = {
            path = ".ssh/hetzner_cloud_debian.8gb.hel1.1.pub";
            reference = "op://Development/Hetzner Cloud debian-8gb-hel1-1/public key";
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
    };
  };
}
