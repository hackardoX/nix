{
  flake.modules.homeManager.base.programs.zsh.initContent = ''
    precmd() {
      local cwd
      cwd=''${PWD/#$HOME/\~}
      print -Pn "\e]0;zsh ''${cwd}\a"
    }
  '';
}
