{ lib, ... }:
{
  flake.modules.homeManager.laptop =
    { pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      targets.darwin.defaults = {
        "com.apple.batteryui.charging.mac" = {
          "com.apple.batteryui.charging.mac.prior.limit" = 80;
        };
      };
    };
}
