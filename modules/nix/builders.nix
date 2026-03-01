{ config, inputs, ... }:
{
  configurations.darwin.rosetta-bootstrap.module = {
    imports = with config.flake.modules.darwin; [
      base
      hackardo
    ];
    home-manager.users.${config.flake.meta.users.hackardo.name}.home.stateVersion = "24.11";
    nix.linux-builder.enable = true;
    nixpkgs.hostPlatform = "aarch64-darwin";
    system = {
      primaryUser = config.flake.meta.users.hackardo.name;
      stateVersion = 5;
    };
  };

  flake.modules.darwin.laptop = {
    imports = [
      inputs.nix-rosetta-builder.darwinModules.default
    ];
    nix-rosetta-builder.onDemand = true;
  };
}
