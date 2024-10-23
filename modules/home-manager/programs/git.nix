{ user }:
{
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
}
