{
  lib,
  ...
}:
{
  flake.modules.homeManager.base =
    { osConfig, pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      targets.darwin = {
        defaults = {
          screencapture = {
            disable-shadow = true;
            location = "/Users/${osConfig.system.primaryUser}/Pictures/Screenshots/";
          };
        };
      };
    };
}
