{ config, lib, ... }:
let
  host = config.flake.nixosConfigurations.HomeLab-CI.config;
  inherit (config.flake.lib.homelab.check) mkCheck;

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
      checks."homelab/firewall" = mkCheck pkgs "firewall" firewallFailures;
    };
}
