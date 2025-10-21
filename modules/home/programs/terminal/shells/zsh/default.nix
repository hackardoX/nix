{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.strings) fileContents;

  cfg = config.${namespace}.programs.terminal.shell.zsh;
in
{
  options.${namespace}.programs.terminal.shell.zsh = {
    enable = mkEnableOption "ZSH";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.zsh-completions ];

    programs = {
      zsh = {
        enable = true;
        package = pkgs.zsh;

        autocd = true;
        completionInit = # Bash
          ''
            autoload -U compinit
            zmodload zsh/complist

            _comp_options+=(globdots)
            zcompdump="$XDG_DATA_HOME"/zsh/.zcompdump-"$ZSH_VERSION"-"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
            compinit -d "$zcompdump"

            # Recompile zcompdump if it exists and is newer than zcompdump.zwc
            # compdumps are marked with the current date in yyyy-mm-dd format
            # which means this is likely to recompile daily
            # also see: <https://htr3n.github.io/2018/07/faster-zsh/>
            if [[ -s "$zcompdump" && (! -s "$zcompdump".zwc || "$zcompdump" -nt "$zcompdump".zwc) ]]; then
              zcompile "$zcompdump"
            fi

            # Load bash completion functions.
            autoload -U +X bashcompinit && bashcompinit

            ${fileContents ./rc/comp.zsh}
          '';

        dotDir = "${config.home.homeDirectory}/.config/zsh";
        enableCompletion = true;

        history = {
          append = true;
          expireDuplicatesFirst = true;
          # saves timestamps to the histfile
          extended = true;
          findNoDups = true;
          ignoreDups = true;
          ignoreSpace = true;
          # avoid cluttering $HOME with the histfile
          path = "${config.home.homeDirectory}/.config/zsh/zsh_history";
          # optimize size of the histfile by avoiding duplicates or commands we don't need remembered
          save = 100000;
          saveNoDups = true;
          # share history between different zsh sessions
          share = true;
          size = 100000;
        };

        sessionVariables = {
          LC_ALL = "en_US.UTF-8";
          KEYTIMEOUT = 0;
          ZVM_VI_ESCAPE_BINDKEY = "jj";
          ZVM_INIT_MODE = "sourcing";
        };

        syntaxHighlighting = {
          enable = true;
          package = pkgs.zsh-syntax-highlighting;
        };

        initContent =
          # Bash
          lib.mkOrder 600 ''
            # binds, zsh modules and everything else
            ${fileContents ./rc/binds.zsh}
            ${fileContents ./rc/fzf-tab.zsh}
          '';

        plugins = [
          # Must be before plugins that wrap widgets, such as zsh-autosuggestions or fast-syntax-highlighting
          {
            name = "fzf-tab";
            src = pkgs.zsh-fzf-tab;
            file = "share/fzf-tab/fzf-tab.plugin.zsh";
          }
          {
            name = "zsh-nix-shell";
            src = pkgs.zsh-nix-shell;
            file = "share/zsh-nix-shell/nix-shell.plugin.zsh";
          }
          {
            name = "zsh-vi-mode";
            src = pkgs.zsh-vi-mode;
            file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
          }
          {
            name = "zsh-autosuggestions";
            src = pkgs.zsh-autosuggestions;
            file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
          }
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
          {
            name = "zsh-fzf-history-search";
            src = pkgs.zsh-fzf-history-search;
            file = "share/zsh-fzf-history-search/zsh-fzf-history-search.plugin.zsh";
          }
        ];
      };
    };
  };
}
