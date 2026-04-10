let
  mkTroubleKeymap =
    {
      key,
      action,
      desc,
    }:
    {
      key = "<Leader>x${key}";
      action = "<cmd>${action}<CR>";
      inherit desc;
    };
in
{
  flake.modules.nixvim.dev = {
    plugins = {
      web-devicons.enable = true;
      trouble = {
        enable = true;
        settings = {
          auto_close = true;
          auto_jump = true;
          auto_refresh = true;
          follow = false;
        };
      };
    };
    keymaps = map mkTroubleKeymap [
      {
        key = "x";
        action = "Trouble diagnostics toggle";
        desc = "Diagnostics (Trouble)";
      }
      {
        key = "l";
        action = "Trouble lsp toggle";
        desc = "Toogle LSP (Trouble)";
      }
      {
        key = "D";
        action = "Trouble lsp_declarations toggle";
        desc = "Toggle LSP declarations (Trouble)";
      }
      {
        key = "d";
        action = "Trouble lsp_definitions toggle";
        desc = "Toggle LSP definitions (Trouble)";
      }
      {
        key = "i";
        action = "Trouble lsp_implementations toggle";
        desc = "Toggle LSP implementations (Trouble)";
      }
      {
        key = "r";
        action = "Trouble lsp_references toggle";
        desc = "Toggle LSP references (Trouble)";
      }
      {
        key = "t";
        action = "Trouble lsp_type_definitions toggle";
        desc = "Toggle LSP type definitions (Trouble)";
      }
      {
        key = "q";
        action = "Trouble quickfix toggle";
        desc = "Toggle quickfix (Trouble)";
      }
      {
        key = "f";
        action = "Trouble focus";
        desc = "Focus (Trouble)";
      }
    ];
  };
}
