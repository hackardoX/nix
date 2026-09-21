{
  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      lsp.servers.starpls = {
        enable = true;
        packageFallback = true;
      };

      extraPackagesAfter = [ pkgs.buildifier ];
      plugins.conform-nvim.settings.formatters_by_ft.bzl = [ "buildifier" ];
    };
}
