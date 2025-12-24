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
  flake.modules.nixos.base = polyModule;
  flake.modules.darwin.base = polyModule;
}
