{
  flake.modules.homeManager.base =
    { config, ... }:
    {
      programs.zsh = {
        # Place zsh config files in XDG-compliant directory instead of $HOME
        dotDir = "${config.home.homeDirectory}/.config/zsh";
        enableCompletion = true;
        sessionVariables = {
          LC_ALL = "en_US.UTF-8";
          # No delay between switching vim modes (instant mode change)
          KEYTIMEOUT = 0;
          # Use 'jj' to exit insert mode in vim mode (instead of ESC)
          ZVM_VI_ESCAPE_BINDKEY = "jj";
          # Load zsh-vi-mode in sourcing mode to prevent conflicts with other plugins
          ZVM_INIT_MODE = "sourcing";
        };
      };
    };
}
