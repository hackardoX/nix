{
  lib,
  ...
}:
{
  flake.modules.homeManager.laptop =
    hmArgs@{ pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      targets.darwin = {
        defaults = {
          screencapture = {
            disable-shadow = true;
            location = "${hmArgs.config.home.homeDirectory}/Pictures/Screenshots/";
          };
        };
      };
    };
}
