{ config, ... }:
let
  beszelHubPort = toString config.flake.meta.reverse-proxy.ports.beszel;
  defaultBeszelUrl = "http://localhost:${beszelHubPort}";

  # Build a Beszel single-system widget for Homepage.
  # Default fields metrics enabled:
  #   cpu, memory, disk, network
  # Usage:
  #   widget = config.flake.lib.beszel.mkWidget {
  #     systemId = "My System";
  #     fields = [ "cpu" "memory" "disk" ];   # optional
  #   };
  mkBeszelWidget =
    {
      systemId,
      fields ? [
        "cpu"
        "memory"
        "disk"
        "network"
      ],
    }:
    {
      type = "beszel";
      url = defaultBeszelUrl;
      version = 2;
      # Resolved by Homepage from the files named by these environment
      # variables (set on the homepage container), not stored in the config.
      username = "{{HOMEPAGE_FILE_BESZEL_USER}}";
      password = "{{HOMEPAGE_FILE_BESZEL_PASSWORD}}";
      inherit
        systemId
        fields
        ;
    };
in
{
  flake.lib.beszel.mkWidget = mkBeszelWidget;
}
