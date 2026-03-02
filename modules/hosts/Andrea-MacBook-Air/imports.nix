{ config, ... }:
{
  configurations.darwin.Andrea-MacBook-Air.module.imports = with config.flake.modules.darwin; [
    base
    dev
    hackardo
    laptop
    password-manager
    shell
    theme
  ];

  configurations.darwin.Andrea-MacBook-Air-CI.module = {
    imports = [ config.configurations.darwin.Andrea-MacBook-Air.module ];
    linux-builder.enable = false;
  };
}
