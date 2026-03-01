{ inputs, ... }:
{
  flake.modules.darwin.laptop = {
    imports = [
      inputs.nix-rosetta-builder.darwinModules.default
    ];
    nix-rosetta-builder.onDemand = true;

    # nix.linux-builder.enable = true;
  };
}
