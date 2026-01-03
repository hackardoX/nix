{ lib, ... }:
{
  flake.modules.homeManager.base =
    homeArgs:
    let
      zsh = lib.getExe homeArgs.config.programs.zsh.package;
    in
    {
      programs.yazi.settings = {
        open.edit = [
          {
            run = "$EDITOR %s";
            block = true;
            for = "unix";
          }
        ];
        keymap.manager.prepend_keymap = [
          {
            on = [ "<S-Enter>" ];
            run = ''shell "${zsh} -c 'cd \"$(dirname \"$0\")\" && exec ${zsh}'" --block --confirm'';
            desc = "Open shell in current/parent directory";
          }
        ];
      };
    };
}
