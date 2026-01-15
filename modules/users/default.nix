{ lib, ... }:
{
  flake.modules.nixos.base.options.system.primaryUser = lib.mkOption {
    type = lib.types.str;
    description = "The username of the primary user of the system.";
  };
}
