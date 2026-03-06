{
  flake.modules.homeManager.dev = {
    programs.java.enable = true;
  };

  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      plugins = {
        lsp.servers.jdtls.enable = true;
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
