{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.${namespace}.programs.terminal.tools.git;
in
{
  config = mkIf cfg.enable {
    # #
    # Git alias
    # #
    # Original: https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/git/git.plugin.zsh
    home = {
      shellAliases = {
        "ga" = "git add";
        "gaa" = "git add --all";
        "gb" = "git branch";
        "gba" = "git branch --all";
        "gbd" = "git branch --delete";
        "gbD" = "git branch --delete --force";
        "gbgd" =
          "git branch --no-color -vv | grep \": gone\]\" | awk '\"'\"'{print $1}'\"'\"' | xargs git branch -d";
        "gc" = "git commit --signoff --verbose";
        "gc!" = "git commit --signoff --verbose --amend";
        "gcn!" = "git commit --signoff --verbose --no-edit --amend";
        "gca" = "git commit --signoff --verbose --all";
        "gca!" = "git commit --signoff --verbose --all --amend";
        "gcan!" = "git commit --signoff --verbose --all --no-edit --amend";
        "gcans!" = "git commit --signoff --verbose --all --signoff --no-edit --amend";
        "gcl" = "git clone --recurse-submodules";
        "gcmsg" = "git commit --signoff --message";
        "gcp" = "git cherry-pick";
        "gcpa" = "git cherry-pick --abort";
        "gcpc" = "git cherry-pick --continue";
        "gd" = "git diff";
        "gds" = "git diff --staged";
        "gdup" = "git diff @{upstream}";
        "gf" = "git fetch";
        "gfa" = "git fetch --all --prune --jobs=10";
        "gfo" = "git fetch origin";
        "glo" = "git log --oneline --decorate";
        "glol" =
          "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset'";
        "glods" =
          "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset' --date=short";
        "glog" = "git log --oneline --decorate --graph";
        "gloga" = "git log --oneline --decorate --graph --all";
        "gm" = "git merge";
        "gma" = "git merge --abort";
        "gms" = "git merge --squash";
        "gr" = "git remote";
        "gra" = "git remote add";
        "grb" = "git rebase";
        "grba" = "git rebase --abort";
        "grbc" = "git rebase --continue";
        "grbd" = "git rebase $(git_develop_branch)";
        "grbi" = "git rebase --interactive";
        "grbm" = "git rebase $(git_main_branch)";
        "grbom" = "git rebase origin/$(git_main_branch)";
        "grbo" = "git rebase --onto";
        "grbs" = "git rebase --skip";
        "grev" = "git revert";
        "grh" = "git reset";
        "grhh" = "git reset --hard";
        "groh" = "git reset origin/$(git_current_branch) --hard";
        "grm" = "git rm";
        "grmc" = "git rm --cached";
        "grs" = "git restore";
        "grset" = "git remote set-url";
        "grss" = "git restore --source";
        "grst" = "git restore --staged";
        "gsb" = "git status --short --branch";
        "gsh" = "git show";
        "gsps" = "git show --pretty=short --show-signature";
        "gss" = "git status --short";
        "gst" = "git status";
        "gsta" = "git stash push";
        "gstaa" = "git stash apply";
        "gstc" = "git stash clear";
        "gstd" = "git stash drop";
        "gstl" = "git stash list";
        "gstp" = "git stash pop";
        "gsts" = "git stash show --text";
        "gsu" = "git submodule update";
        "gsw" = "git switch";
        "gswc" = "git switch --create";
        "gswm" = "git switch $(git_main_branch)";
        "gswd" = "git switch $(git_develop_branch)";
        "gwt" = "git worktree";
        "gwta" = "git worktree add";
        "gwtls" = "git worktree list";
        "gwtmv" = "git worktree move";
        "gwtrm" = "git worktree remove";
      };
      # // lib.optionalAttrs (config.programs.gh.enable) {
      #   "ghrc" = "gh repo clone";
      # };
    };

    programs.bash.shellAliases = {
      "gbda" =
        "git branch --no-color --merged | command grep -vE \"^([+*]|\s*($(git_main_branch)|$(git_develop_branch))\s*$)\" | command xargs git branch --delete 2>/dev/null";
    };

    programs.zsh.shellAliases = {
      "gbda" =
        "git branch --no-color --merged | command grep -vE \"^([+*]|\s*($(git_main_branch)|$(git_develop_branch))\s*$)\" | command xargs git branch --delete 2>/dev/null";
    };
  };
}
