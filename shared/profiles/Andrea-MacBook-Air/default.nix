{
  lib,
  namespace,
  ...
}: let 
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
      };
    };
    music = enabled;
    networking = enabled;
  };
}
