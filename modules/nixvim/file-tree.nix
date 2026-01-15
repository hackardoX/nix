{
  flake.modules.nixvim.dev = {
    plugins.yazi = {
      enable = true;
      settings = {
        open_for_directories = true;
      };
      # More details: https://github.com/mikavilpas/yazi.nvim/issues/802
      luaConfig.pre = "vim.g.loaded_netrwPlugin = 1";
    };

    keymaps = [
      {
        mode = [
          "n"
          "v"
        ];
        key = "<leader>-";
        action = "<cmd>Yazi<cr>";
        options = {
          desc = "Open yazi at the current file";
        };
      }
      {
        mode = "n";
        key = "<leader>cw";
        action = "<cmd>Yazi cwd<cr>";
        options = {
          desc = "Open the file manager in nvim's working directory";
        };
      }
      {
        mode = "n";
        key = "<leader>+";
        action = "<cmd>Yazi toggle<cr>";
        options = {
          desc = "Resume the last yazi session";
        };
      }
    ];
  };
}
