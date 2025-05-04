{
  nix-homebrew,
  homebrew-core,
  homebrew-cask,
  homebrew-bundle,
  ...
}:
{ user, ... }:
{
  imports = [
    nix-homebrew.darwinModules.nix-homebrew
    {
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
      brews = builtins.import ./brews.nix;
      casks = builtins.import ./casks.nix;
      enable = true;
      masApps = builtins.import ./mas.nix;
      onActivation = {
        cleanup = "zap";
        autoUpdate = true;
        upgrade = true;
      };
    };
  };
}
