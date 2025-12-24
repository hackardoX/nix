{ lib, ... }:
{
  flake.modules.homeManager.base =
    { pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      targets.darwin = {
        defaults = {
          NSGlobalDomain = {
            AppleICUForce24HourTime = true;
          };

          "com.apple.menuextra.clock" = {
            Show24Hour = true;
            ShowDayOfWeek = true;
            ShowSeconds = false;
            ShowTime = true;
            ShowDate = 0;
          };
        };
      };
    };
}
