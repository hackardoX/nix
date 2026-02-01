{ config, ... }:
{
  flake.modules.nixos.homelab = {
    security.acme = {
      acceptTerms = true;
      defaults.email = config.flake.meta.users.hackardo.email;
    };
  };
}
