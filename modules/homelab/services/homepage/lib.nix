{ config, ... }:
let
  beszelHubPort = toString config.flake.meta.reverse-proxy.ports.beszel;
  defaultBeszelUrl = "http://localhost:${beszelHubPort}";

  # Build a Beszel single-system widget for Homepage.
  # Default fields metrics enabled:
  #   cpu, memory, disk, network
  # Usage:
  #   widget = config.flake.lib.mkBeszelWidget {
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
      inherit
        systemId
        fields
        ;
    };
in
{
  flake.lib.mkBeszelWidget = mkBeszelWidget;
}
