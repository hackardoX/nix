{
  description = "Private inputs for the homelab partition. Used by the top-level flake in the `homelab` partition; not present in the root lock file.";

  inputs = {
    asahi-firmware = {
      url = "git+ssh://git@github.com/hackardoX/nixos-asahi-firmware.git?shallow=1";
      flake = false;
    };

    nixos-apple-silicon = {
      url = "github:nix-community/nixos-apple-silicon";
      inputs.nixpkgs.follows = "";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "";
    };

    nix-mineral = {
      url = "github:cynicsketch/nix-mineral";
      inputs = {
        flake-compat.follows = "";
        flake-parts.url = "github:hercules-ci/flake-parts";
        nixpkgs.follows = "";
      };
    };
  };

  outputs = _: { };
}
