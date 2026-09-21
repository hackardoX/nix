{
  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      lsp.servers.yamlls = {
        enable = true;
        packageFallback = true;
      };

      extraPackagesAfter = [ pkgs.prettierd ];
      plugins.conform-nvim.settings.formatters_by_ft.yaml = [ "prettierd" ];
    };
}
