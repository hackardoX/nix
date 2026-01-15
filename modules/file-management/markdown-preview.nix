{ lib, ... }:
{
  flake.modules.homeManager.laptop =
    { pkgs, ... }:
    {
      home = {
        packages = [
          pkgs.rich-cli
        ];
        sessionVariables = {
          # Solution from https://github.com/Textualize/rich-cli/issues/73
          PYTHONWARNINGS = "ignore:The parameter -j is used more than once:UserWarning:click.core:";
        };
      };

      programs.yazi = {
        settings = {
          plugin.prepend_previewers = [
            {
              url = "*.md";
              run = ''piper -- ${lib.getExe pkgs.rich-cli} -j --left --panel=rounded --guides --line-numbers --force-terminal "$1"'';
            }
          ];
        };
      };
    };
}
