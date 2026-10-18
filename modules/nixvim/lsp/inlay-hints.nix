{ inputs, ... }:
{
  flake.modules.nixvim.dev.lsp = {
    inlayHints.enable = true;
    keymaps = [
      {
        key = "<Leader>lh";
        mode = "n";
        action = inputs.nixvim.lib.nixvim.mkRaw ''
          function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
            local message = vim.lsp.inlay_hint.is_enabled() and "Inlay hint is off" or "Inlay hint is on"
            vim.notify(message, vim.log.levels.INFO, { title = "Inlay Hint Toggle" })
          end
        '';
        options.desc = "Toggle inlay hints";
      }
    ];
  };
}
