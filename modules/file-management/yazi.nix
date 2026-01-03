{ lib, ... }:
{
  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      programs.yazi = {
        enable = true;
        enableZshIntegration = true;
        settings = {
          opener = {
            open = [
              {
                run = ''open "$@"'';
                desc = "Open";
                for = "macos";
              }
              {
                run = ''${lib.getExe' pkgs.xdg-utils "xdg-open"} "$@"'';
                desc = "Open";
                for = "linux";
              }
            ];
            edit = [
              {
                run = ''$EDITOR "$@"'';
                block = true;
              }
            ];
          };
          open.rules = [
            {
              mime = "text/*";
              use = "edit";
            }
            {
              mime = "*";
              use = "open";
            }
          ];
        };
      };
    };
}
