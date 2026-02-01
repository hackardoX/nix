{
  config,
  inputs,
  lib,
  ...
}:
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

  config.flake.deploy.nodes =
    let
      nixosNodes =
        config.configurations.nixos or { }
        |> lib.filterAttrs (_name: cfg: cfg.deploy != null)
        |> lib.mapAttrs (
          name: cfg:
          let
            nixosConfig = config.flake.nixosConfigurations.${name};
            system = nixosConfig.config.nixpkgs.hostPlatform.system;
          in
          {
            hostname = cfg.deploy.hostname;
            profiles.system = {
              sshUser = cfg.deploy.sshUser;
              user = nixosConfig.config.system.primaryUser;
              path = inputs.deploy-rs.lib.${system}.activate.nixos nixosConfig;
            };
          }
        );

      darwinNodes =
        config.configurations.darwin or { }
        |> lib.filterAttrs (_name: cfg: cfg.deploy != null)
        |> lib.mapAttrs (
          name: cfg:
          let
            darwinConfig = config.flake.darwinConfigurations.${name};
            system = darwinConfig.config.nixpkgs.hostPlatform.system;
          in
          {
            hostname = cfg.deploy.hostname;
            profiles.system = {
              sshUser = cfg.deploy.sshUser;
              user = darwinConfig.config.system.primaryUser;
              path = inputs.deploy-rs.lib.${system}.activate.darwin darwinConfig;
            };
          }
        );
    in
    nixosNodes // darwinNodes;
}
