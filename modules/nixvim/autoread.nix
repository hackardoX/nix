{
  flake.modules.nixvim.dev =
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
    };
}
