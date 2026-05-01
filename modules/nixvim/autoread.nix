{ inputs, ... }:
{
  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      extraConfigLua = ''
        vim.o.autoread = true;
        vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
          callback = function()
            if vim.fn.mode() ~= 'c' then
              vim.cmd('checktime')
            end
          end
        })
      '';

      # extraPlugins = [
      #   {
      #     plugin = pkgs.vimUtils.buildVimPlugin {
      #       pname = "vim-autoread";
      #       version = "unstable";
      #       src = inputs.vim-autoread;
      #     };
      #     config = ''
      #       autocmd VimEnter * nested WatchForChangesAllFile!
      #     '';
      #   }
      # ];
    };
}
