{ inputs, ... }:
{
  flake.modules.nixvim.dev.lsp = {
    codelens.enable = true;
    keymaps = [
      {
        key = "<Leader>lt";
        mode = "n";
        action = inputs.nixvim.lib.nixvim.mkRaw ''
          function()
            vim.lsp.codelens.enable(not vim.lsp.codelens.is_enabled())
            local message = vim.lsp.codelens.is_enabled() and "Codelens is off" or "Codelens is on"
            vim.notify(message, vim.log.levels.INFO, { title = "CodeLens Toggle" })
          end
        '';
        options.desc = "Toggle codelens";
      }
    ];
  };
}
