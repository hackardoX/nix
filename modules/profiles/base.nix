{ config, ... }:
{
  flake.modules.darwin.base = {
    imports = with config.flake.modules.darwin; [
      archives
      homebrew
      nix
      zsh
    ];
  };

  flake.modules.nixos.base = {
    imports = with config.flake.modules.nixos; [
      archives
      auto-upgrade
      disko
      nix
      zsh
    ];
  };

  flake.modules.homeManager.base = {
    imports = with config.flake.modules.homeManager; [
      bash
      nix
      zsh
    ];
  };
}
