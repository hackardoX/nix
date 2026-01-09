{ lib, ... }:
{
  flake.modules.homeManager.base =
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
                run = lib.getExe pkgs.duckdb;
                multi = false;
              }) multiFileTypes;

            prepend_previewers =
              let
                fileTypes = [
                  "csv"
                  "db"
                  "duckdb"
                  "json"
                  "parquet"
                  "tsv"
                  "xlsx"
                ];
              in
              map (ext: {
                url = "*.${ext}";
                run = lib.getExe pkgs.duckdb;
              }) fileTypes;
          };
        };
      };
    };
}
