{
  flake.modules.nixvim.base = {
    plugins.yazi = {
      enable = true;
      settings = {
        open_for_directories = false;
        keymaps = {
          show_help = "<f1>";
        };
      };
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
        key = "<c-up>";
        action = "<cmd>Yazi toggle<cr>";
        options = {
          desc = "Resume the last yazi session";
        };
      }
    ];
  };
}
