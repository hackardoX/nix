{ inputs, ... }:
{
  flake.modules.nixvim.dev = {
    plugins.lspconfig.enable = true;
    lsp = {
      servers."*".config.capabilities = inputs.nixvim.lib.nixvim.mkRaw ''
        vim.tbl_deep_extend("force", require('cmp_nvim_lsp').default_capabilities(), {
          textDocument = { semanticTokens = { multilineTokenSupport = true } },
        })
      '';
    };
  };
}
