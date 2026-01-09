{ config, ... }:
{
  configurations.darwin.Andrea-MacBook-Air.module = {
    imports = with config.flake.modules.darwin; [
      base
      # dev
      media
      password-manager
    ];
  };
}
