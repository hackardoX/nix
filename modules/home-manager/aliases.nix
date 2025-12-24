{ lib, ... }:
{
  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      home = {
        shellAliases = {
          # File management
          wget = "${lib.getExe pkgs.wget} -c ";

          # Navigation shortcuts
          ".." = "cd ..";
          "..." = "cd ../..";
          "...." = "cd ../../..";
          "....." = "cd ../../../..";
          "......" = "cd ../../../../..";
          myipv4 = "${lib.getExe pkgs.curl} api.ipify.org";
          myipv6 = "${lib.getExe pkgs.curl} api6.ipify.org";
        };
      };
    };
}
