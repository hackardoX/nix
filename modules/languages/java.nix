{
  flake.modules.homeManager.dev = {
    programs.java.enable = true;
  };

  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      plugins = {
        lsp.servers.jdtls.enable = true;
        conform-nvim = {
          enable = true;
          settings = {
            formatters_by_ft.java = [ "injected" ];
            format_on_save = {
              timeout_ms = 3000;
              lsp_format = "fallback";
            };
          };
        };
        iron = {
          settings = {
            config = {
              repl_definition = {
                java.command = [ "${pkgs.jdk}/bin/jshell" ];
              };
            };
          };
        };
      };

      keymaps = [
        {
          mode = "n";
          key = "<leader>rj";
          action = "<cmd>IronRepl java<cr>";
          options.desc = "Force start Java REPL";
        }
      ];
    };
}
