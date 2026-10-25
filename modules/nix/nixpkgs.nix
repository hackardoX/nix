{ self, ... }:
let
  polyModule = {
    nixpkgs = {
      config = {
        # allowBroken = true;
        allowUnfree = true;
        # showDerivationWarnings = [ "maintainerless" ];
        permittedInsecurePackages = [ ];
      };
      overlays = builtins.attrValues self.overlays;
    };
  };
in
{
  flake.modules.nixos.nix = polyModule;
  flake.modules.darwin.nix = polyModule;
}
