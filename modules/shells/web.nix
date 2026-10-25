{ lib, ... }:
let
  polyModule =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        curl
        wget
      ];
    };
in
{
  flake.modules.nixos.web = polyModule;
  flake.modules.darwin.web = polyModule;
  flake.modules.homeManager.web =
    { pkgs, ... }:
    {
      home = {
        shellAliases = {
          wget = "${lib.getExe pkgs.wget} -c ";
          myipv4 = "${lib.getExe pkgs.curl} api.ipify.org";
          myipv6 = "${lib.getExe pkgs.curl} api6.ipify.org";
        };
      };
    };
}
