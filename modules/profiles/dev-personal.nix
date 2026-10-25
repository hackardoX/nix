{ config, ... }:
{
  flake.modules.homeManager.dev-personal = {
    imports = with config.flake.modules.homeManager; [
      ai-agents
      ai-lumo
      cli-docs
      comma
      direnv
      gh-dash
      ghostty
      git-extras
      lang-css
      lang-html
      lang-javascript
      lang-json
      lang-nix
      lang-python
      lang-xml
      lazygit
      nixvim
      nono
      opencode
      podman
      starship
      workmux
    ];
  };
}
