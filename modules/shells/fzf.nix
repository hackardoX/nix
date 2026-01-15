{
  lib,
  ...
}:
{
  flake.modules.homeManager.shell =
    { pkgs, ... }:
    {
      programs.fzf = {
        enable = true;

        defaultCommand = "${lib.getExe pkgs.fd} --type=f --hidden --exclude=.git";
        defaultOptions = [
          "--layout=reverse"
          "--exact"
          "--bind=alt-p:toggle-preview,alt-a:select-all"
          "--multi"
          "--no-mouse"
          "--info=inline"

          "--ansi"
          "--with-nth=1.."
          "--pointer=' '"
          "--header-first"
          "--border=rounded"
        ];

        enableBashIntegration = true;
        enableZshIntegration = true;
        enableFishIntegration = true;
      };
    };
}
