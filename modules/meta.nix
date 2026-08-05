{ lib, ... }:
{
  options.flake.meta = lib.mkOption {
    type = lib.types.submodule {
      options.uri = lib.mkOption {
        type = lib.types.str;
        description = "Repository URI of this flake.";
      };
    };
    default = { };
    description = "Shared metadata store read via config.flake.meta across modules (uri, users, reverse-proxy, oidc-clients, etc.). Each namespace is declared as options.flake.meta.<name> in a per-area meta.nix.";
  };

  options.flake.lib = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.anything;
    default = { };
    description = "Flake-local helper library namespaces published by each module via flake.lib.<ns>.";
  };

  config = {
    flake.meta.uri = "github:hackardoX/nix";
  };
}
