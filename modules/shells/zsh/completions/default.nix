{ lib, ... }:
{
  flake.modules.homeManager.shell.programs.zsh = {
    completionInit = # Bash
      ''
        autoload -U compinit
        zmodload zsh/complist

        # Include hidden files (dotfiles) in completion
        _comp_options+=(globdots)
        # Store completion cache in XDG-compliant location with timestamp
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

        ${lib.strings.fileContents ./comp.zsh}
      '';

    initContent =
      # Bash
      lib.mkOrder 600 ''
        # binds, zsh modules and everything else
        ${lib.strings.fileContents ./binds.zsh}
        ${lib.strings.fileContents ./fzf-tab.zsh}
      '';
  };
}
