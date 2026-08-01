{ inputs, lib, ... }:
let
  isFirstInitialization = true;
in
{
  flake.modules.darwin.base = darwinArgs: {
    options.linux-builder.enable = lib.mkEnableOption "linux-builder" // {
      default = true;
    };

    imports = [ inputs.nix-rosetta-builder.darwinModules.default ];

    config = {
      nix.linux-builder = {
        enable = darwinArgs.config.linux-builder.enable && isFirstInitialization;
        ephemeral = true;
      };
      nix-rosetta-builder = {
        enable = darwinArgs.config.linux-builder.enable && !isFirstInitialization;
        onDemand = true;
      };
    };
  };
}
