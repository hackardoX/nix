{ lib, ... }:
{
  flake.modules.homeManager.laptop =
    { pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      targets.darwin = {
        defaults = {
          NSGlobalDomain = {
            ApplePressAndHoldEnabled = false;
            KeyRepeat = 2;
            InitialKeyRepeat = 15;
          };
        };
      };
    };
}
