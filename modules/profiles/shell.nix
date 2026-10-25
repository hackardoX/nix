{ config, ... }:
{
  flake.modules.homeManager.shell = {
    imports = with config.flake.modules.homeManager; [
      aliases
      archives
      atuin
      bat
      carapace
      eza
      file-management
      fzf
      web
      window-titles
      zellij
      zoxide
      zsh-config
    ];
  };
}
