let
  troublePrefix = "<Leader>x";
  mkTroubleKeymap =
    {
      key,
      action,
      desc,
    }:
    {
      key = "${troublePrefix}${key}";
      action = "<cmd>${action}<CR>";
      options = {
        inherit desc;
      };
    };
  troubleKeymaps = map mkTroubleKeymap [
    {
      key = "x";
      action = "Trouble diagnostics toggle";
      desc = "Diagnostics";
    }
    {
      key = "l";
      action = "Trouble lsp toggle";
      desc = "Toogle LSP";
    }
    {
      key = "D";
      action = "Trouble lsp_declarations toggle";
      desc = "Toggle LSP declarations";
    }
    {
      key = "d";
      action = "Trouble lsp_definitions toggle";
      desc = "Toggle LSP definitions";
    }
    {
      key = "i";
      action = "Trouble lsp_implementations toggle";
      desc = "Toggle LSP implementations";
    }
    {
      key = "r";
      action = "Trouble lsp_references toggle";
      desc = "Toggle LSP references";
    }
    {
      key = "t";
      action = "Trouble lsp_type_definitions toggle";
      desc = "Toggle LSP type definitions";
    }
    {
      key = "q";
      action = "Trouble quickfix toggle";
      desc = "Toggle quickfix";
    }
    {
      key = "f";
      action = "Trouble focus";
      desc = "Focus";
    }
  ];

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
      which-key = {
        settings.spec = [
          {
            __unkeyed-1 = troublePrefix;
            group = "Trouble (${toString (builtins.length troubleKeymaps)} keymaps)";
          }
        ];
      };
    };
    keymaps = troubleKeymaps;
  };
}
