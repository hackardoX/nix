{
  flake.modules.homeManager.dev =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        diffnav
      ];

      programs = {
        difftastic = {
          options.background = "dark";
          enable = true;
          git.enable = true;
        };
        lazygit.settings = {
          git.diff = {
            externalDiffCommand = "difft --color=always";
          };
        };
        git.settings.diff.algorithm = "histogram";
      };
    };
}
