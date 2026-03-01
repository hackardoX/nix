{ inputs, ... }:
{
  flake.packages.aarch64-linux.linux-builder =
    inputs.nixpkgs.legacyPackages.aarch64-linux.darwin.linux-builder;

  flake.modules.darwin.laptop = {
    imports = [
      inputs.nix-rosetta-builder.darwinModules.default
    ];
    nix-rosetta-builder.onDemand = true;
  };
}
