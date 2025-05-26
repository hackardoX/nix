{
  config,
  lib,
  ...
}:
{
  shellAliases =
    {
      # #
      # Git alias
      # #
      # Original: https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/git/git.plugin.zsh
      "ga" = "git add";
      "gaa" = "git add --all";
      "gb" = "git branch";
      "gba" = "git branch --all";
      "gbd" = "git branch --delete";
      "gbda" =
        "git branch --no-color --merged | command grep -vE \"^([+*]|\s*($(git_main_branch)|$(git_develop_branch))\s*$)\" | command xargs git branch --delete 2>/dev/null";
      "gbD" = "git branch --delete --force";
      "gbgd" =
        "git branch --no-color -vv | grep \": gone\]\" | awk '\"'\"'{print $1}'\"'\"' | xargs git branch -d";
      "gc" = "git commit --verbose";
      "gc!" = "git commit --verbose --amend";
      "gcn!" = "git commit --verbose --no-edit --amend";
      "gca" = "git commit --verbose --all";
      "gca!" = "git commit --verbose --all --amend";
      "gcan!" = "git commit --verbose --all --no-edit --amend";
      "gcans!" = "git commit --verbose --all --signoff --no-edit --amend";
      "gcl" = "git clone --recurse-submodules";
      "gcmsg" = "git commit --message";
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
      __git_prompt_git = # Bash
        ''
          !f() {                                                                     \
            GIT_OPTIONAL_LOCKS=0 command git \"$@\";                                 \
          }; f'';
      git_current_branch = # Bash
        ''
          !f() {                                                                     \
            local ref                                                                \
            ref=$(__git_prompt_git symbolic-ref --quiet HEAD 2> /dev/null)           \
            local ret=$?                                                             \
            if [[ $ret != 0 ]]; then                                                 \
              [[ $ret == 128 ]] && return  # no git repo.                            \
              ref=$(__git_prompt_git rev-parse --short HEAD 2> /dev/null) || return  \
            fi                                                                       \
            echo \''${ref#refs/heads/}
          }; f'';
      ggfl = # Bash
        ''
          "!f() {                                                                    \
            [[ "$#" != 1 ]] && local b="$(git_current_branch)"                       \
            git push --force-with-lease origin "''${b:=$1}"                          \
          }; f'';
      ggl = # Bash
        ''
          !f() {                                                                     \ 
            if [[ "$#" != 0 ]] && [[ "$#" != 1 ]]; then                              \
              git pull origin "''${*}"                                               \
            else                                                                     \
              [[ "$#" == 0 ]] && local b="$(git_current_branch)"                     \
              git pull origin "''${b:=$1}"                                           \
            fi                                                                       \
          }; f'';
      ggp = # Bash
        ''
          !f() {                                                                     \ 
            if [[ "$#" != 0 ]] && [[ "$#" != 1 ]]; then                              \
              git push origin "''${*}"                                               \
            else                                                                     \
              [[ "$#" == 0 ]] && local b="$(git_current_branch)"                     \
              git push origin "''${b:=$1}"                                           \
            fi                                                                       \
          }; f'';
    }
    // lib.mkIf config.programs.gh.enable {
      ghrc = "gh repo clone";
      ghrck = "gh repo clone khaneliman/";
    };
}
