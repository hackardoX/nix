{ config, pkgs, lib, ... }:

let user = "aaccardo"; in
{
  # Shared shell configuration
  zsh = {
    enable = true;
    autocd = false;

    oh-my-zsh = {
      enable = false;
    };

    initExtraFirst = ''
      if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
      fi

      # Define variables for directories
      export PATH=$HOME/.npm-packages/bin:$HOME/bin:$PATH
      export PATH=$HOME/.local/share/bin:$PATH

      export HISTIGNORE="pwd:ls:cd:eza:bat:z"

      export EDITOR="code --wait"
      export VISUAL="code --wait"

      # nix shortcuts
      shell() {
          nix-shell '<nixpkgs>' -A "$1"
      }

      # Always color ls and group directories
      alias cd="z"
      alias ..="cd .."
      alias ...="cd ../.."
      alias ....="cd ../../.."
      alias ls="eza"
      alias cat="bat"

    '' + builtins.readFile ./config/git-aliases.zsh;
  };

  git = {
    enable = true;
    extraConfig = {
      branch = {
        sort = "-committerdate";
      };
      column = {
        ui = "auto";
      };
      core = {
        editor = "code --wait --new-window";
      };
      pull.rebase = true;
      rebase.autoStash = true;
    };
    includes = [
      {
        condition = "gitdir:~/Github/";
        path = "/Users/${user}/Github/.gitconfig";
      }
    ];
    ignores = [ ".DS_Store" ];
  };

  ssh = {
    enable = true;
    includes = [
      (lib.mkIf pkgs.stdenv.hostPlatform.isLinux
        "/home/${user}/.ssh/config_external"
      )
      (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
        "/Users/${user}/.ssh/config_external"
      )
    ];
    matchBlocks = {
      "github.com" = {
        identitiesOnly = true;
        identityFile = [
          (lib.mkIf pkgs.stdenv.hostPlatform.isLinux
            "/home/${user}/.ssh/id_github"
          )
          (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
            "/Users/${user}/.ssh/id_github"
          )
        ];
      };
    };
  };

  vscode = builtins.import ./apps/vscode.nix {};

  # zoxide = {
    # enable = true;
    # enableBashIntegration = true;
    # enableFishIntegration = false;
    # enableNushellIntegration = false;
    # enableZshIntegration = true;
  # };
}
