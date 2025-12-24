{ lib, ... }:
{
  options.flake.meta = lib.mkOption {
    type = lib.types.anything;
  };

  config = {
    flake.meta.uri = "github:hackardoX/nix";
  };
}
