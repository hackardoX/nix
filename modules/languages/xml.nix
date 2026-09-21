{ lib, ... }:
{
  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      lsp.servers.lemminx = {
        enable = true;
        packageFallback = true;
      };
      extraPackagesAfter = [ pkgs.xmlformat ];
      plugins.conform-nvim.settings.formatters_by_ft.xml = [ "xmlformatter" ];
    };

  flake.modules.homeManager.dev =
    { pkgs, ... }:
    {
      programs.opencode = {
        extraPackages = [ pkgs.lemminx ];
        settings.lsp.lemminx = {
          command = [
            (lib.getExe pkgs.lemminx)
            "-l"
            "stdio"
          ];
          extensions = [
            ".xml"
            ".xsd"
            ".xsl"
            ".xslt"
            ".dtd"
          ];
        };
      };
    };
}
