{
  flake.modules.homeManager.shell =
    { config, ... }:
    {
      programs.zsh = {
        history = {
          append = true;
          # Remove older duplicate entries before unique ones when history is full
          expireDuplicatesFirst = true;
          # saves timestamps to the histfile
          extended = true;
          # Don't show duplicate entries when searching history
          findNoDups = true;
          ignoreDups = true;
          ignoreSpace = true;
          # avoid cluttering $HOME with the histfile
          path = "${config.home.homeDirectory}/.config/zsh/zsh_history";
          # optimize size of the histfile by avoiding duplicates or commands we don't need remembered
          save = 100000;
          # Don't write duplicate entries to history file
          saveNoDups = true;
          # share history between different zsh sessions
          share = true;
          size = 100000;
        };
      };
    };
}
