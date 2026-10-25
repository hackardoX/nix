{ inputs, ... }:
{
  flake.modules.nixos.nix = {
    imports = [
      inputs.nix-index-database.nixosModules.nix-index
    ];

    programs = {
      nix-index.enable = true;
    };
  };

  flake.modules.darwin.nix = {
    imports = [
      inputs.nix-index-database.darwinModules.nix-index
    ];

    programs = {
      nix-index.enable = true;
    };
  };
}
