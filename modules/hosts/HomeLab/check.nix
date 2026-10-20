{ config, lib, ... }:
let
  host = config.flake.nixosConfigurations.HomeLab-CI.config;
  inherit (config.flake.lib.checks) mkCheck mkSystemdCheck;

  firewallPorts = lib.sort lib.lessThan host.networking.firewall.allowedTCPPorts;
  firewallFailures = lib.optional (
    firewallPorts != [
      22
      80
      443
    ]
  ) "networking.firewall.allowedTCPPorts is [ ${toString firewallPorts} ], expected [ 22 80 443 ]";
in
{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        "homelab/firewall" = mkCheck pkgs "homelab/firewall" firewallFailures;
      }
      // lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "aarch64-linux") {
        "homelab/validate-systemd-iwd-wifi" = mkSystemdCheck host pkgs "homelab/validate-systemd-iwd-wifi" [
          "setup-iwd-wifi.service"
        ];
      };
    };
}
