{ inputs, ... }:
{
  flake.modules.nixos.hetzner = {
    imports = [ inputs.disko.nixosModules.disko ];
  };
}
