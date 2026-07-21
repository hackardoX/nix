{ lib, ... }:
{
  flake.modules.homeManager.shell =
    { pkgs, ... }:
    {
      programs.yazi = {
        enable = true;
        enableZshIntegration = true;
        shellWrapperName = "y";
        initLua = ''
          require("full-border"):setup()
        '';

        plugins =
          let
            mux = pkgs.stdenvNoCC.mkDerivation {
              pname = "mux.yazi";
              version = "unstable";
              src = pkgs.fetchFromGitHub {
                owner = "peterfication";
                repo = "mux.yazi";
                rev = "main";
                hash = "sha256-Cf/gtv3uIwXtkp6pEZJSkylA3vHpmQqrWOLo2FLg9yA=";
              };
              installPhase = ''
                cp -r $src $out
              '';
            };
          in
          {
            inherit (pkgs.yaziPlugins) full-border piper;
            inherit mux;
          };

        keymap = {
          mgr.prepend_keymap = [
            {
              on = [ "P" ];
              run = "plugin mux next";
              desc = "Cycle previewer";
            }
          ];
        };

        settings = {
          mgr.ratio = [
            1
            2
            5
          ];
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
