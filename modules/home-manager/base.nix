{ lib, ... }:
{
  flake.modules.homeManager.base =
    { osConfig, ... }:
    {
      home = {
        username = osConfig.system.primaryUser;
        homeDirectory = lib.mkForce "/Users/${osConfig.system.primaryUser}";
        # if pkgs.stdenv.hostPlatform.isDarwin then
        #   "/Users/${config.primaryUser}"
        # else
        #   "/home/${config.primaryUser}";
      };
      programs.home-manager.enable = true;
    };
}
