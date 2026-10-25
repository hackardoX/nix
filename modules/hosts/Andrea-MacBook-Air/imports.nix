{ config, ... }:
{
  configurations.darwin.Andrea-MacBook-Air.module = {
    imports = with config.flake.modules.darwin; [
      config.flake.modules.darwin."1password"
      hackardo
      base
      macos
      media
      messaging
      nix-workstation
      rclone
      raycast
      sops
      sudo
    ];

    home-manager.users.${config.flake.meta.users.hackardo.name} =
      config.flake.modules.homeManager.hackardo;
  };

  configurations.darwin.Andrea-MacBook-Air-CI.module = {
    imports = [ config.configurations.darwin.Andrea-MacBook-Air.module ];
    linux-builder.enable = false;
  };
}
