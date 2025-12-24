{
  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      programs.zsh = {
        plugins = [
          # Must be before plugins that wrap widgets, such as zsh-autosuggestions or fast-syntax-highlighting
          # Replaces zsh's default completion menu with fzf fuzzy finder
          {
            name = "fzf-tab";
            src = pkgs.zsh-fzf-tab;
            file = "share/fzf-tab/fzf-tab.plugin.zsh";
          }
          # Provides better integration when using nix-shell
          {
            name = "zsh-nix-shell";
            src = pkgs.zsh-nix-shell;
            file = "share/zsh-nix-shell/nix-shell.plugin.zsh";
          }
          # Enables vim keybindings in zsh
          {
            name = "zsh-vi-mode";
            src = pkgs.zsh-vi-mode;
            file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
          }
          # Suggests commands as you type based on history and completions
          {
            name = "zsh-autosuggestions";
            src = pkgs.zsh-autosuggestions;
            file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
          }
          # Synchronizes completion definitions across sessions
          {
            name = "zsh-completion-sync";
            src = pkgs.fetchFromGitHub {
              owner = "BronzeDeer";
              repo = "zsh-completion-sync";
              rev = "v0.3.3";
              sha256 = "GTW4nLVW1/09aXNnZJuKs12CoalzWGKB79VsQ2a2Av4=";
            };
            file = "zsh-completion-sync.plugin.zsh";
          }
          # Fuzzy search through command history using fzf
          {
            name = "zsh-fzf-history-search";
            src = pkgs.zsh-fzf-history-search;
            file = "share/zsh-fzf-history-search/zsh-fzf-history-search.plugin.zsh";
          }
        ];
      };
    };
}
