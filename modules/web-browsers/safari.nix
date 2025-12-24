{ lib, ... }:
{
  flake.modules.homeManager.base =
    { pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      targets.darwin = {
        defaults = {
          "com.apple.Safari" = {
            IncludeDevelopMenu = true;
          };
        };
      };
    };
}
