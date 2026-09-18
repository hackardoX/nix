_: {
  flake.modules.nixvim.dev = _: {
    lsp.servers.yamlls.enable = true;

    plugins.conform-nvim.settings.formatters_by_ft.yaml = [ "prettierd" ];
  };
}
