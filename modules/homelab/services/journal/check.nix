{ config, lib, ... }:
let
  host = config.flake.nixosConfigurations.HomeLab-CI.config;
  inherit (config.flake.lib.checks) mkSystemdCheck;
in
{
  perSystem =
    { pkgs, ... }:
    {
      checks = lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "aarch64-linux") {
        "homelab/validate-systemd-grafito" = mkSystemdCheck host pkgs "homelab/validate-systemd-grafito" [
          "grafito.service"
        ];
      };
    };
}
