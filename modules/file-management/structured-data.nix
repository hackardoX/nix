{
  flake.modules.homeManager.laptop =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.duckdb
      ];

      programs.yazi = {
        initLua = ''
          require("duckdb"):setup()
        '';

        plugins = {
          inherit (pkgs.yaziPlugins) duckdb;
        };

        settings = {
          plugin = {
            prepend_preloaders =
              let
                multiFileTypes = [
                  "csv"
                  "tsv"
                  "json"
                  "parquet"
                  "xlsx"
                ];
              in
              map (ext: {
                url = "*.${ext}";
                run = "duckdb";
                multi = false;
              }) multiFileTypes;

            prepend_previewers =
              let
                fileTypes = [
                  "csv"
                  "db"
                  "duckdb"
                  "parquet"
                  "tsv"
                  "xlsx"
                ];
              in
              map (ext: {
                url = "*.${ext}";
                run = "mux duckdb code";
              }) fileTypes
              ++ [
                {
                  url = "*.json";
                  run = "mux code duckdb";
                }
              ];

          };
        };
      };
    };
}
