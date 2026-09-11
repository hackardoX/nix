{ lib, ... }:
{
  options.flake.meta.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Login/user name.";
            };

            email = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Email address of the user.";
            };

            description = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Human-readable description of the user.";
            };

            uid = lib.mkOption {
              type = lib.types.nullOr lib.types.int;
              default = null;
              description = "UID for the user.";
            };

            primaryGroup = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = config.name;
              description = "Primary group of the user, falling back to the user name.";
            };

            git = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  name = lib.mkOption {
                    type = lib.types.str;
                    description = "Git user name.";
                  };

                  email = lib.mkOption {
                    type = lib.types.str;
                    description = "Git user email.";
                  };
                };
              };
              description = "Git configuration for the user.";
            };
          };
        }
      )
    );
    default = { };
    description = "User records shared across nix-darwin, NixOS and home-manager modules.";
  };
}
