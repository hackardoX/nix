{ config, ... }:
{
  configurations.darwin.Andrea-MacBook-Air.module = {
    home-manager.users.${config.flake.meta.users.hackardo.name}.programs.onepassword-secrets.secrets = {
      andreaMacBookAirPublicKey = {
        path = ".ssh/andrea_mac_book_air.pub";
        reference = "op://Development/Andrea MacBook Air/public key";
        group = "staff";
      };
      andreaMacBookAirPrivateKey = {
        path = ".ssh/andrea_mac_book_air";
        reference = "op://Development/Andrea MacBook Air/private key";
        group = "staff";
      };
      homeLabPublicKey = {
        path = ".ssh/homelab.pub";
        reference = "op://HomeLab/Hal/public key";
        group = "staff";
      };
      homeLabInitrdPublicKey = {
        path = ".ssh/homelab_initrd.pub";
        reference = "op://HomeLab/Initrd Luks/public key";
        group = "staff";
      };
    };
  };
}
