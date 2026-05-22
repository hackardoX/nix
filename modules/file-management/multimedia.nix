{
  flake.modules.homeManager.laptop =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.mediainfo
        pkgs.imagemagick
        pkgs.ffmpeg
      ];

      programs.yazi = {
        plugins = {
          inherit (pkgs.yaziPlugins) mediainfo;
        };

        settings = {
          plugin = {
            prepend_preloaders = [
              {
                mime = "{audio}/*";
                run = "mediainfo";
              }
              {
                mime = "{image}/*";
                run = "mediainfo --no-metadata";
              }
              {
                mime = "{video}/*";
                run = "mediainfo --no-preview";
              }
              {
                mime = "application/subrip";
                run = "mediainfo";
              }
            ];
            prepend_previewers = [
              {
                mime = "{audio}/*";
                run = "mediainfo";
              }
              {
                mime = "{image}/*";
                run = "mediainfo --no-metadata";
              }
              {
                mime = "{video}/*";
                run = "mediainfo --no-preview";
              }
              {
                mime = "application/subrip";
                run = "mediainfo";
              }
            ];
          };
        };
      };
    };
}
