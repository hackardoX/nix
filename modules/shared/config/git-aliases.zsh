# Original: https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/git/git.plugin.zsh
#
# Functions
#

# Check if main exists and use instead of master
function git_main_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local ref
  for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default}; do
    if command git show-ref -q --verify $ref; then
      echo ${ref:t}
      return
    fi
  done
  echo master
}

# Check for develop and similarly named branches
function git_develop_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local branch
  for branch in dev devel development; do
    if command git show-ref -q --verify refs/heads/$branch; then
      echo $branch
      return
    fi
  done
  echo develop
}

function ggfl() {
  [[ "$#" != 1 ]] && local b="$(git_current_branch)"
  git push --force-with-lease origin "${b:=$1}"
}

function ggl() {
  if [[ "$#" != 0 ]] && [[ "$#" != 1 ]]; then
    git pull origin "${*}"
  else
    [[ "$#" == 0 ]] && local b="$(git_current_branch)"
    git pull origin "${b:=$1}"
  fi
}

function ggp() {
  if [[ "$#" != 0 ]] && [[ "$#" != 1 ]]; then
    git push origin "${*}"
  else
    [[ "$#" == 0 ]] && local b="$(git_current_branch)"
    git push origin "${b:=$1}"
  fi
}

#
# Aliases
# (sorted alphabetically)
#

alias ga='git add'
alias gaa='git add --all'
alias gb='git branch'
alias gba='git branch --all'
alias gbd='git branch --delete'
alias gbda='git branch --no-color --merged | command grep -vE "^([+*]|\s*($(git_main_branch)|$(git_develop_branch))\s*$)" | command xargs git branch --delete 2>/dev/null'
alias gbD='git branch --delete --force'
alias gbgd='git branch --no-color -vv | grep ": gone\]" | awk '"'"'{print $1}'"'"' | xargs git branch -d'
alias gc='git commit --verbose'
alias gc!='git commit --verbose --amend'
alias gcn!='git commit --verbose --no-edit --amend'
alias gca='git commit --verbose --all'
alias gca!='git commit --verbose --all --amend'
alias gcan!='git commit --verbose --all --no-edit --amend'
alias gcans!='git commit --verbose --all --signoff --no-edit --amend'
alias gcl='git clone --recurse-submodules'
alias gcmsg='git commit --message'
alias gcp='git cherry-pick'
alias gcpa='git cherry-pick --abort'
alias gcpc='git cherry-pick --continue'
alias gd='git diff'
alias gds='git diff --staged'
alias gdup='git diff @{upstream}'
alias gf='git fetch'
alias gfa='git fetch --all --prune --jobs=10'
alias gfo='git fetch origin'
alias glo='git log --oneline --decorate'
alias glol="git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset'"
alias glods="git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset' --date=short"
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'
alias gm='git merge'
alias gma='git merge --abort'
alias gms="git merge --squash"
alias gr='git remote'
alias gra='git remote add'
alias grb='git rebase'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbd='git rebase $(git_develop_branch)'
alias grbi='git rebase --interactive'
alias grbm='git rebase $(git_main_branch)'
alias grbom='git rebase origin/$(git_main_branch)'
alias grbo='git rebase --onto'
alias grbs='git rebase --skip'
alias grev='git revert'
alias grh='git reset'
alias grhh='git reset --hard'
alias groh='git reset origin/$(git_current_branch) --hard'
alias grm='git rm'
alias grmc='git rm --cached'
alias grs='git restore'
alias grset='git remote set-url'
alias grss='git restore --source'
alias grst='git restore --staged'
alias gsb='git status --short --branch'
alias gsh='git show'
alias gsps='git show --pretty=short --show-signature'
alias gss='git status --short'
alias gst='git status'
alias gsta='git stash push' \
alias gstaa='git stash apply'
alias gstc='git stash clear'
alias gstd='git stash drop'
alias gstl='git stash list'
alias gstp='git stash pop'
alias gsts='git stash show --text'
alias gsu='git submodule update'
alias gsw='git switch'
alias gswc='git switch --create'
alias gswm='git switch $(git_main_branch)'
alias gswd='git switch $(git_develop_branch)'
alias gwt='git worktree'
alias gwta='git worktree add'
alias gwtls='git worktree list'
alias gwtmv='git worktree move'
alias gwtrm='git worktree remove'

# Discarded

# alias g='git'
# alias gapa='git add --patch'
# alias gau='git add --update'
# alias gav='git add --verbose'
# alias gap='git apply'
# alias gapt='git apply --3way'
# alias gbg='git branch -vv | grep ": gone\]"'
# alias gbgD='git branch --no-color -vv | grep ": gone\]" | awk '"'"'{print $1}'"'"' | xargs git branch -D'
# alias gbl='git blame -b -w'
# alias gbnm='git branch --no-merged'
# alias gbr='git branch --remote'
# alias gbs='git bisect'
# alias gbsb='git bisect bad'
# alias gbsg='git bisect good'
# alias gbsr='git bisect reset'
# alias gbss='git bisect start'
# alias gcam='git commit --all --message'
# alias gcsm='git commit --signoff --message'
# alias gcas='git commit --all --signoff'
# alias gcasm='git commit --all --signoff --message'
# alias gcb='git checkout -b'
# alias gcf='git config --list'
# alias gclean='git clean --interactive -d'
# alias gpristine='git reset --hard && git clean --force -dfx'
# alias gcm='git checkout $(git_main_branch)'
# alias gcd='git checkout $(git_develop_branch)'
# alias gco='git checkout'
# alias gcor='git checkout --recurse-submodules'
# alias gcount='git shortlog --summary --numbered'
# alias gcs='git commit --gpg-sign'
# alias gcss='git commit --gpg-sign --signoff'
# alias gcssm='git commit --gpg-sign --signoff --message'
# alias gdca='git diff --cached'
# alias gdcw='git diff --cached --word-diff'
# alias gdct='git describe --tags $(git rev-list --tags --max-count=1)'
# alias gdt='git diff-tree --no-commit-id --name-only -r'
# alias gdw='git diff --word-diff'
# alias gfg='git ls-files | grep'
# alias ggpull='git pull origin "$(git_current_branch)"'
# alias ggpush='git push origin "$(git_current_branch)"'
# alias ggsup='git branch --set-upstream-to=origin/$(git_current_branch)'
# alias gpsup='git push --set-upstream origin $(git_current_branch)'
# alias gpsupf='git push --set-upstream origin $(git_current_branch) --force-with-lease --force-if-includes' \
# alias ghh='git help'
# alias gignore='git update-index --assume-unchanged'
# alias gignored='git ls-files -v | grep "^[[:lower:]]"'
# alias git-svn-dcommit-push='git svn dcommit && git push github $(git_main_branch):svntrunk'
# alias gl='git pull'
# alias glg='git log --stat'
# alias glgp='git log --stat --patch'
# alias glgg='git log --graph'
# alias glgga='git log --graph --decorate --all'
# alias glgm='git log --graph --max-count=10'
# alias glols="git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --stat"
# alias glod="git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset'"
# alias glola="git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --all"
# alias gmom='git merge origin/$(git_main_branch)'
# alias gmtl='git mergetool --no-prompt'
# alias gmtlvim='git mergetool --no-prompt --tool=vimdiff'
# alias gmum='git merge upstream/$(git_main_branch)'
# alias gp='git push'
# alias gpd='git push --dry-run'
# alias gpf='git push --force-with-lease --force-if-includes'
# alias gpf!='git push --force'
# alias gpoat='git push origin --all && git push origin --tags'
# alias gpod='git push origin --delete'
# alias gpr='git pull --rebase'
# alias gpu='git push upstream'
# alias gpv='git push --verbose'
# alias grmv='git remote rename'
# alias grrm='git remote remove'
# alias grt='cd "$(git rev-parse --show-toplevel || echo .)"'
# alias gru='git reset --'
# alias grup='git remote update'
# alias grv='git remote --verbose'
# alias gstu='gsta --include-untracked'
# alias gstall='git stash --all'
# alias gts='git tag --sign'
# alias gtv='git tag | sort -V'
# alias gunignore='git update-index --no-assume-unchanged'
# alias gunwip='git rev-list --max-count=1 --format="%s" HEAD | grep -q "\--wip--" && git reset HEAD~1'
# alias gup='git pull --rebase'
# alias gupv='git pull --rebase --verbose'
# alias gupa='git pull --rebase --autostash'
# alias gupav='git pull --rebase --autostash --verbose'
# alias gupom='git pull --rebase origin $(git_main_branch)'
# alias gupomi='git pull --rebase=interactive origin $(git_main_branch)'
# alias glum='git pull upstream $(git_main_branch)'
# alias gluc='git pull upstream $(git_current_branch)'
# alias gwch='git whatchanged -p --abbrev-commit --pretty=medium'
# alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign --message "--wip-- [skip ci]"'
# alias gam='git am'
# alias gamc='git am --continue'
# alias gams='git am --skip'
# alias gama='git am --abort'
# alias gamscp='git am --show-current-patch'