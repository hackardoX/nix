{
  description = "Private inputs for the laptops partition. Used by the top-level flake in the `laptops` partition; not present in the root lock file.";

  inputs = {
    atuin-ai-server = {
      url = "github:atuinsh/atuin-ai-server";
      flake = false;
    };
    custom-homebrew-formulas = {
      url = "github:hackardox/homebrew-formulas";
      flake = false;
    };
    hex-homebrew-tap = {
      url = "github:anomalyco/homebrew-tap";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
    };
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };
    nix-rosetta-builder = {
      url = "github:cpick/nix-rosetta-builder";
      inputs.nixpkgs.follows = "";
    };
    superpowers = {
      url = "github:obra/superpowers";
      flake = false;
    };
    systems = {
      url = "github:nix-systems/default";
    };
  };

  outputs = _: { };
}
