{ lib, ... }:
{
  options = {
    configurations.nixos = lib.mkOption {
      type = lib.types.lazyAttrsOf (
        lib.types.submodule {
          options.deploy = lib.mkOption {
            type = lib.types.nullOr (
              lib.types.submodule {
                options = {
                  hostname = lib.mkOption {
                    type = lib.types.str;
                    description = "Hostname or IP to deploy to";
                  };
                  sshUser = lib.mkOption {
                    type = lib.types.str;
                    default = "root";
                    description = "SSH user for deployment";
                  };
                };
              }
            );
            default = null;
            description = "Deploy configuration for this host";
          };
        }
      );
    };

    configurations.darwin = lib.mkOption {
      type = lib.types.lazyAttrsOf (
        lib.types.submodule {
          options.deploy = lib.mkOption {
            type = lib.types.nullOr (
              lib.types.submodule {
                options = {
                  hostname = lib.mkOption {
                    type = lib.types.str;
                    description = "Hostname or IP to deploy to";
                  };
                  sshUser = lib.mkOption {
                    type = lib.types.str;
                    default = "root";
                    description = "SSH user for deployment";
                  };
                };
              }
            );
            default = null;
            description = "Deploy configuration for this host";
          };
        }
      );
    };
  };
}
