{ lib, ... }:
{
  flake.modules.homeManager.base =
    { osConfig, pkgs, ... }:
    {
      home = {
        username = osConfig.system.primaryUser;
        homeDirectory = lib.mkForce (
          if pkgs.stdenv.hostPlatform.isDarwin then
            "/Users/${osConfig.system.primaryUser}"
          else
            "/home/${osConfig.system.primaryUser}"
        );
      };
      programs.home-manager.enable = true;
    };
}
