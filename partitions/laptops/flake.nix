{
  description = "Private inputs for the laptops partition. Used by the top-level flake in the `laptops` partition; not present in the root lock file.";

  inputs = {
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    custom-homebrew-formulas = {
      url = "github:hackardox/homebrew-formulas";
      flake = false;
    };

    nix-rosetta-builder = {
      url = "github:cpick/nix-rosetta-builder";
      inputs.nixpkgs.follows = "";
    };
  };

  outputs = _: { };
}
