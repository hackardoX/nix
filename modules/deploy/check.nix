{
  config,
  inputs,
  lib,
  ...
}:
{
  perSystem =
    { pkgs, system, ... }:
    {
      checks = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux (
        inputs.deploy-rs.lib.${system}.deployChecks config.flake.deploy or { }
      );
    };
}
