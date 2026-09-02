{ config, ... }:
{
  configurations.darwin.Proton-MacBook-Pro.module = {
    imports = with config.flake.modules.darwin; [
      aaccardo
      base
      dev
      media
      proton-pass
    ];

    home-manager.users.${config.flake.meta.users.aaccardo.name} =
      config.flake.modules.homeManager.aaccardo;
  };

  configurations.darwin.Proton-MacBook-Pro-CI.module = {
    imports = [ config.configurations.darwin.Proton-MacBook-Pro.module ];
    linux-builder.enable = false;
  };
}
