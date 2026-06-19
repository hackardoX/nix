{ lib, ... }:
{
  flake.modules.homeManager.homelab =
    hmArgs:
    let
      extractHostPort = portMapping: lib.head (lib.splitString ":" portMapping);
    in
    {
      options.services.podman.containers = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule (
            { config, ... }:
            {
              options.monitoring = {
                enable = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "Enable monitoring for this container";
                };

                scrapePort = lib.mkOption {
                  type = lib.types.nullOr lib.types.port;
                  default = if config.ports != [ ] then extractHostPort (lib.head config.ports) else null;
                  defaultText = lib.literalExpression "first port from container ports mapping";
                  description = "Port to scrape metrics from (defaults to first container port's host side)";
                };

                alloy = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                  description = "Enable Alloy log collection from journal";
                };
              };

              config = lib.mkIf config.monitoring.alloy {
                extraConfig.Container.Labels."logging.alloy" = "true";
              };
            }
          )
        );
      };
    };
}
