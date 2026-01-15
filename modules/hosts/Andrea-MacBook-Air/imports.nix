{ config, ... }:
{
  configurations.darwin.Andrea-MacBook-Air.module = {
    imports = with config.flake.modules.darwin; [
      base
      dev
      laptop
      password-manager
      shell
      theme
    ];
  };
}
