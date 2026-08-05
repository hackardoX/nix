{ config, lib, ... }:
{
  options.flake.meta.homepage.services = lib.mkOption {
    type = lib.types.attrsOf config.flake.lib.types.homepageService;
    default = { };
    description = "Homepage service records shared across homelab services.";
  };
}
