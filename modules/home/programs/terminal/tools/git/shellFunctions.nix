{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.${namespace}.programs.terminal.tools.git;
in
{
  config = mkIf cfg.enable {
    programs.zsh.initContent = lib.mkAfter ''
      function __git_prompt_git() {
        GIT_OPTIONAL_LOCKS=0 command git "$@"
      }

      function git_current_branch() {
        local ref
        ref=$(__git_prompt_git symbolic-ref --quiet HEAD 2> /dev/null)
        local ret=$?
        if [[ $ret != 0 ]]; then
          [[ $ret == 128 ]] && return  # no git repo.
          ref=$(__git_prompt_git rev-parse --short HEAD 2> /dev/null) || return
        fi
        echo ''${ref#refs/heads/}
      }

      function ggfl() {
        [[ "$#" != 1 ]] && local b="$(git_current_branch)"
        git push --force-with-lease origin "''${b:=$1}"
      }

      function ggl() {
        if [[ "$#" != 0 ]] && [[ "$#" != 1 ]]; then
          git pull origin "''${*}"
        else
          [[ "$#" == 0 ]] && local b="$(git_current_branch)"
          git pull origin "''${b:=$1}"
        fi
      }

      function ggp() {
        if [[ "$#" != 0 ]] && [[ "$#" != 1 ]]; then
          git push origin "''${*}"
        else
          [[ "$#" == 0 ]] && local b="$(git_current_branch)"
          git push origin "''${b:=$1}"
        fi
      }

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

      function git_main_branch() {
        command git rev-parse --git-dir &>/dev/null || return
        local ref
        for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default}; do
          if command git show-ref -q --verify $ref; then
            echo ''${ref:t}
            return
          fi
        done
        echo master
      }
    '';
  };
}