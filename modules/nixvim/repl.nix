{
  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      extraPackages = with pkgs; [
        jdk
        python3
        nodejs
        lua
      ];

      plugins.iron = {
        enable = true;
        settings = {
          config = {
            repl_open_cmd = {
              __raw = "require('iron.view').bottom(40)";
            };
          };
        };
      };

      keymaps = [
        {
          mode = "n";
          key = "<leader>rs";
          action = "<cmd>IronRepl<cr>";
          options.desc = "Start REPL for current filetype";
        }
        {
          mode = "v";
          key = "<leader>rv";
          action = "<cmd>IronSend<cr>";
          options.desc = "Send selection to REPL";
        }
        {
          mode = "n";
          key = "<leader>rr";
          action = "<cmd>IronRestart<cr>";
          options.desc = "Restart REPL";
        }
      ];
    };
}
