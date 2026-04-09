{
  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      extraPackages = with pkgs; [
        lua
        stylua
      ];

      plugins = {
        lsp.servers.lua_ls.enable = true;

        conform-nvim.settings = {
          formatters_by_ft.lua = [ "stylua" ];
          formatters.stylua.command = "${pkgs.stylua}/bin/stylua";
        };
      };
    };
}
