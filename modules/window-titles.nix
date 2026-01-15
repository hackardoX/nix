{
  flake.modules.homeManager.shell.programs.zsh.initContent = ''
    precmd() {
      local cwd
      cwd=''${PWD/#$HOME/\~}
      print -Pn "\e]0;zsh ''${cwd}\a"
    }
  '';
}
