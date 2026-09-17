{
  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      extraPackages = with pkgs; [ coreutils ];

      # Must run at startup (not when yazi lazy-loads) to keep netrw disabled.
      # More details: https://github.com/mikavilpas/yazi.nvim/issues/802
      extraConfigLuaPre = "vim.g.loaded_netrwPlugin = 1";

      plugins.yazi = {
        enable = true;
        lazyLoad.settings.cmd = [ "Yazi" ];
        settings = {
          open_for_directories = true;
        };
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
