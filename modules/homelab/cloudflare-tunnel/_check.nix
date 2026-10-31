{ config, lib, ... }:
let
  host = config.flake.nixosConfigurations.HomeLab-CI.config;
  inherit (config.flake.lib.checks) mkSystemdCheck;

  # The tunnel unit is named after the tunnel UUID.
  tunnelUnits = map (n: "${n}.service") (
    lib.filter (n: lib.hasPrefix "cloudflared-tunnel-" n) (lib.attrNames host.systemd.services)
  );
in
{
  perSystem =
    { pkgs, ... }:
    {
      checks = lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "aarch64-linux") {
        "homelab/validate-systemd-cloudflare-tunnel" =
          mkSystemdCheck host pkgs "homelab/validate-systemd-cloudflare-tunnel"
            tunnelUnits;
      };
    };
}
