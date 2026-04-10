let
  mkTelescopeKeymap =
    {
      key,
      action,
    }:
    {
      name = "<Leader>f${key}";
      value = {
        inherit action;
      };
    };
in
{
  flake.modules.nixvim.dev.plugins.telescope.keymaps = builtins.listToAttrs (
    map mkTelescopeKeymap [
      {
        key = "f";
        action = "find_files";
      }
      {
        key = "g";
        action = "live_grep";
      }
      {
        key = "b";
        action = "buffers";
      }
      {
        key = "h";
        action = "help_tags";
      }
      {
        key = "c";
        action = "commands";
      }
      {
        key = "q";
        action = "quickfix";
      }
      {
        key = "k";
        action = "keymaps";
      }
      {
        key = "r";
        action = "lsp_references";
      }
      {
        key = "ds";
        action = "lsp_document_symbols";
      }
      {
        key = "s";
        action = "lsp_workspace_symbols";
      }
      {
        key = "p";
        action = "diagnostics";
      }
      {
        key = "i";
        action = "lsp_implementations";
      }
      {
        key = "d";
        action = "lsp_definitions";
      }
      {
        key = "t";
        action = "lsp_type_definitions";
      }
      {
        key = "a";
        action = "builtin";
      }
      {
        key = ";";
        action = "resume";
      }
    ]
  );
}
