{ lib, ... }:
{
  flake.modules.homeManager.base =
    { pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      targets.darwin = {
        defaults = {
          NSGlobalDomain = {
            "com.apple.sound.beep.feedback" = 0;
            "com.apple.sound.beep.volume" = 0.0;
          };
        };
      };
    };
}
