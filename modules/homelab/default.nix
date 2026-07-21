{ lib, ... }:
{
  options.flake.homelab.services = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          user = lib.mkOption {
            type = lib.types.str;
            description = "The system user under which this service's HM module runs.";
          };

          module = lib.mkOption {
            type = lib.types.nullOr lib.types.deferredModule;
            default = null;
            description = "Home Manager module function for this service.";
          };
        };
      }
    );
    default = { };
    description = "Homelab services to route into per-user Home Manager scopes.";
  };
}
