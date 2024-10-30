{
  nix-homebrew,
  homebrew-core,
  homebrew-cask,
  homebrew-bundle,
  system
}:
{ lib, user, ... }:
{
  imports = [
    nix-homebrew.darwinModules.nix-homebrew {
      nix-homebrew = {
        enable = true;
        taps = {
          "homebrew/homebrew-core" = homebrew-core;
          "homebrew/homebrew-cask" = homebrew-cask;
          "homebrew/homebrew-bundle" = homebrew-bundle;
        };
        mutableTaps = false;
        autoMigrate = true;
        inherit user;
      };
    }
  ];
  
  config = {
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
}
