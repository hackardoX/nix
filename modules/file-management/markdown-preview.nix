{
  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.rich-cli
      ];

      programs.yazi = {
        plugins = {
          inherit (pkgs.yaziPlugins) rich-preview;
        };

        settings = {
          plugin.prepend_previewers = [
            {
              url = "*.md";
              run = "rich-preview";
            }
          ];
        };
      };
    };
}
