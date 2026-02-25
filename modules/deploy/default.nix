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
            type = lib.types.nullOr lib.types.attrs;
            default = null;
            description = "All deploy-rs options";
          };
        }
      );
    };

    configurations.darwin = lib.mkOption {
      type = lib.types.lazyAttrsOf (
        lib.types.submodule {
          options.deploy = lib.mkOption {
            type = lib.types.nullOr lib.types.attrs;
            default = null;
            description = "All deploy-rs options";
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
              path = inputs.deploy-rs.lib.${system}.activate.nixos nixosConfig;
              sshUser = lib.mkDefault config.flake.meta.users.deploy.name;
            }
            // cfg.deploy;
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
              path = inputs.deploy-rs.lib.${system}.activate.darwin darwinConfig;
              sshUser = lib.mkDefault config.flake.meta.users.deploy.name;
            }
            // cfg.deploy;
          }
        );
    in
    nixosNodes // darwinNodes;
}
