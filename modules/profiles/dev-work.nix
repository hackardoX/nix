{ config, ... }:
{
  flake.modules.homeManager.dev-work = {
    imports = with config.flake.modules.homeManager; [
      ai-agents
      ai-lumo
      ccusage
      claude-code
      cli-docs
      comma
      devenv
      direnv
      gh-dash
      ghostty
      git-extras
      lang-css
      lang-html
      lang-java
      lang-javascript
      lang-json
      lang-kotlin
      lang-nix
      lang-python
      lang-rust
      lang-swift
      lang-xml
      lazygit
      nixvim
      nono
      opencode
      podman
      starship
      tuicr
      workmux
    ];
  };
}
