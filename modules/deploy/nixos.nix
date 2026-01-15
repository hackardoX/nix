{
  config,
  inputs,
  lib,
  ...
}:
{
  flake.deploy.nodes =
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
          user = "root";
          path = inputs.deploy-rs.lib.${system}.activate.nixos nixosConfig;
        };
      }
    );
}
