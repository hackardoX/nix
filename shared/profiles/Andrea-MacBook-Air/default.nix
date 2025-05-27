{
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) enabled;
in
{
  suites = {
    business = enabled;
    common = enabled;
    development = {
      enable = true;
      aiEnable = true;
      dockerEnable = true;
      nixEnable = true;
      sqlEnable = true;
      git = {
        user = "andrea11";
        email = "10788630+andrea11@users.noreply.github.com";
      };
      ssh = {
        authorizedKeys = [ ];
        allowed_signers = [
          "10788630+andrea11@users.noreply.github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHsOzI1TFwbRy/GgE2/fNJR8B7gfIogp//2kDJ7D1uSB"
        ];
      };
    };
    music = enabled;
    networking = enabled;
  };
}
