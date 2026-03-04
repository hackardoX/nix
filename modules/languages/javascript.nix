{
  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      extraPackages = with pkgs; [
        nodejs
        nodePackages.typescript
        nodePackages.typescript-language-server
      ];

      plugins = {
        lsp.servers = {
          biome.enable = true;
          eslint.enable = true;
        };
        typescript-tools = {
          enable = true;
          settings.single_file_support = true;
        };
        conform-nvim = {
          enable = true;
          settings.formatters_by_ft = {
            typescript = [
              "biome"
              "eslint"
            ];
            javascript = [
              "biome"
              "eslint"
            ];
          };
        };
        iron = {
          settings = {
            config = {
              repl_definition = {
                javascript.command = [ "node" ];
                typescript.command = [ "node" ];
              };
            };
          };
        };
      };

      keymaps = [
        {
          mode = "n";
          key = "<leader>rt";
          action = "<cmd>IronRepl typescript<cr>";
          options.desc = "Force start TypeScript REPL";
        }
      ];
    };
}
