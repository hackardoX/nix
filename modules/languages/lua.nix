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

        iron.settings.config.repl_definition = {
          lua.command = [ "lua" ];
        };
      };

      keymaps = [
        {
          mode = "n";
          key = "<leader>rl";
          action = "<cmd>IronRepl lua<cr>";
          options.desc = "Force start Lua REPL";
        }
      ];
    };
}
