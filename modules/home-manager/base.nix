{ lib, ... }:
{
  flake.modules.homeManager.base =
    { config, pkgs, ... }:
    {
      home.homeDirectory = lib.mkDefault (
        if pkgs.stdenv.hostPlatform.isDarwin then
          "/Users/${config.home.username}"
        else
          "/home/${config.home.username}"
      );
      programs.home-manager.enable = true;
    };
}
