{ inputs, ... }:
{
  perSystem = { system, ... }: {
    make-shells.default.packages = [
      inputs.deploy-rs.packages.${system}.deploy-rs
    ];
  };
}
