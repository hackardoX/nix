{ config, ... }:
{
  configurations.darwin.Andrea-MacBook-Air.module = {
    imports = with config.flake.modules.darwin; [
      aaccardo
      base
      dev
      media
      password-manager
    ];

    home-manager.users.${config.flake.meta.users.aaccardo.name} =
      config.flake.modules.homeManager.aaccardo;
  };

  configurations.darwin.Andrea-MacBook-Air-CI.module = {
    imports = [ config.configurations.darwin.Andrea-MacBook-Air.module ];
    linux-builder.enable = false;
  };
}
