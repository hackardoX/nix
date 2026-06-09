{ lib, ... }:
{
  options.flake.meta = lib.mkOption {
    type = lib.types.anything;
  };

  options.flake.lib = lib.mkOption {
    type = lib.types.anything;
    default = { };
  };

  config = {
    flake.meta.uri = "github:hackardoX/nix";
  };
}
