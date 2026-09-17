{ inputs, ... }:
{
  flake.modules.nixvim.dev.lsp.keymaps = [
    {
      key = "K";
      lspBufAction = "hover";
      options.desc = "Hover";
    }
    {
      key = "<C-k>";
      lspBufAction = "signature_help";
      options.desc = "Signature Help";
    }
    {
      key = "gd";
      lspBufAction = "definition";
      options.desc = "Definition";
    }
    {
      key = "gD";
      lspBufAction = "declaration";
      options.desc = "Declaration";
    }
    {
      key = "gi";
      lspBufAction = "implementation";
      options.desc = "Implementation";
    }
    {
      key = "go";
      lspBufAction = "type_definition";
      options.desc = "Type Definition";
    }
    {
      key = "<space>r";
      lspBufAction = "rename";
      options.desc = "Rename";
    }
    {
      key = "<space>a";
      action = inputs.nixvim.lib.nixvim.mkRaw "vim.lsp.buf.code_action";
      options.desc = "Code Action";
      mode = [
        "n"
        "v"
      ];
    }
  ];
}
