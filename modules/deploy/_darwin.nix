{
  config,
  inputs,
  lib,
  ...
}:
{
  flake.deploy.nodes =
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
          user = darwinConfig.system.primaryUser;
          path = inputs.deploy-rs.lib.${system}.activate.darwin darwinConfig;
        };
      }
    );
}
