{
  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      extraPackages = with pkgs; [ coreutils ];

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
          key = "<Leader>-";
          action = "<cmd>Yazi<cr>";
          options.desc = "Open yazi at the current file";
        }
        {
          mode = "n";
          key = "<Leader>+";
          action = "<cmd>Yazi toggle<cr>";
          options.desc = "Resume the last yazi session";
        }
      ];
    };
}
