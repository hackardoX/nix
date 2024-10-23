{
  description = "A custom flake for nix-homebrew configuration";

  inputs = {
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs =
    { self, ... }:
    {
      darwinModules = {
        custom-homebrew =
          {
            homebrew-core,
            homebrew-cask,
            homebrew-bundle,
          }:
          let
            inherit system;
          in
          {
            nix-homebrew.darwinModules.nix-homebrew = {
              enable = true;
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
                "homebrew/homebrew-bundle" = homebrew-bundle;
              };
              mutableTaps = false;
              autoMigrate = true;
              enableRosetta = builtins.match "aarch64.*" system != null;
            };

            homebrew = {
              enable = true;
              casks = builtins.import ./casks.nix;
              onActivation = {
                cleanup = "zap";
                autoUpdate = true;
                upgrade = true;
              };
              masApps = builtins.import ./mas.nix;
            };
          };
      };
    };
}
