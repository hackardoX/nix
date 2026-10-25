{ lib, ... }:
let
  polyModule =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        zip
        unzip
      ];
    };
in
{
  flake.modules.nixos.archives = polyModule;
  flake.modules.darwin.archives = polyModule;

  flake.modules.homeManager.archives =
    { pkgs, ... }:
    let
      mimeTypes = [
        "application/*zip"
        "application/java-archive"
        "application/vnd.rar"
        "application/x-7z-compressed"
        "application/x-bzip2"
        "application/x-rar"
        "application/x-tar"
        "application/x-xz"
        "application/x-zstd"
        "application/xz"
        "application/zstd"
      ];
    in
    {
      home.packages = [
        pkgs.ouch
      ];

      programs.yazi = {
        plugins = {
          inherit (pkgs.yaziPlugins) ouch;
        };

        settings = {
          plugin.prepend_previewers =
            mimeTypes
            |> map (mime: {
              inherit mime;
              run = "ouch";
            });

          opener.extract = [
            {
              run = ''${lib.getExe pkgs.ouch} decompress --yes "$@"'';
              desc = "Extract here with ouch";
              for = "unix";
            }
          ];

          open.rules =
            mimeTypes
            |> map (mime: {
              inherit mime;
              use = "extract";
            });
        };

        keymap.mgr.prepend_keymap = [
          {
            on = [ "C" ];
            run = "plugin ouch";
            desc = "Compress with ouch";
          }
        ];
      };
    };
}
