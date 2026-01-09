{ inputs, ... }:
{
  flake.modules.nixos.base = {
    imports = [
      inputs.nix-index-database.nixosModules.nix-index
    ];

    programs = {
      nix-index.enable = true;
    };
  };

  flake.modules.darwin.base = {
    imports = [
      inputs.nix-index-database.darwinModules.nix-index
    ];

    programs = {
      nix-index.enable = true;
    };
  };
}
