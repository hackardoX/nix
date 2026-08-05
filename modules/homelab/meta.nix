{ lib, ... }:
{
  options.flake.meta.reverse-proxy = lib.mkOption {
    type = lib.types.submodule {
      options = {
        domain = lib.mkOption {
          type = lib.types.str;
          description = "Base domain for the reverse proxy.";
        };

        hosts = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          description = "Subdomains by service name.";
        };

        ports = lib.mkOption {
          type = lib.types.attrsOf lib.types.int;
          description = "Internal ports by service name.";
        };
      };
    };
    description = "Reverse proxy shared configuration (domain, hostnames and ports).";
  };
}
