{
  flake.modules.nixvim.dev = {
    plugins = {
      treesitter = {
        enable = true;
        folding = {
          enable = true;
        };
        highlight.enable = true;
        indent.enable = true;
      };
      treesitter-context.enable = true;
      treesitter-textobjects = {
        enable = true;
        settings = {
          select = {
            lookahead = true;
            selection_modes = {
              "@parameter.outer" = "v";
              "@function.outer" = "V";
            };
          };
          move = {
            set_jumps = true;
            goto_next_start = {
              "]m" = "@function.outer";
              "]c" = "@class.outer";
              "]o" = {
                query = "@loop.*";
                query_group = "textobjects";
              };
              "]s" = {
                query = "@local.scope";
                query_group = "locals";
              };
              "]z" = {
                query = "@fold";
                query_group = "folds";
              };
            };
            goto_next_end = {
              "]M" = "@function.outer";
              "]C" = "@class.outer";
            };
            goto_previous_start = {
              "[m" = "@function.outer";
              "[c" = "@class.outer";
              "[o" = {
                query = "@loop.*";
                query_group = "textobjects";
              };
            };
            goto_previous_end = {
              "[M" = "@function.outer";
              "[C" = "@class.outer";
            };
          };
        };
      };
    };
    opts.foldlevel = 99;
    keymaps =
      let
        selectMaps =
          let
            mkSelect = key: query: group: {
              mode = [
                "x"
                "o"
              ];
              inherit key;
              action.__raw = "function() require('nvim-treesitter-textobjects.select').select_textobject('${query}', '${group}') end";
            };
          in
          [
            (mkSelect "am" "@function.outer" "textobjects")
            (mkSelect "im" "@function.inner" "textobjects")
            (mkSelect "ac" "@class.outer" "textobjects")
            (mkSelect "ic" "@class.inner" "textobjects")
            (mkSelect "as" "@local.scope" "locals")
          ];

        mkSwap = key: func: query: desc: {
          mode = "n";
          inherit key;
          options.desc = desc;
          action.__raw = "function() require('nvim-treesitter-textobjects.swap').${func}('${query}') end";
        };

        repeatMaps = [
          {
            mode = [
              "n"
              "x"
              "o"
            ];
            key = ";";
            action.__raw = "require('nvim-treesitter-textobjects.repeatable_move').repeat_last_move_next";
          }
          {
            mode = [
              "n"
              "x"
              "o"
            ];
            key = "<BS>";
            action.__raw = "require('nvim-treesitter-textobjects.repeatable_move').repeat_last_move_previous";
          }
        ];

        ftMaps = [
          {
            mode = [
              "n"
              "x"
              "o"
            ];
            key = "f";
            action.__raw = "require('nvim-treesitter-textobjects.repeatable_move').builtin_f_expr";
            options.expr = true;
          }
          {
            mode = [
              "n"
              "x"
              "o"
            ];
            key = "F";
            action.__raw = "require('nvim-treesitter-textobjects.repeatable_move').builtin_F_expr";
            options.expr = true;
          }
          {
            mode = [
              "n"
              "x"
              "o"
            ];
            key = "t";
            action.__raw = "require('nvim-treesitter-textobjects.repeatable_move').builtin_t_expr";
            options.expr = true;
          }
          {
            mode = [
              "n"
              "x"
              "o"
            ];
            key = "T";
            action.__raw = "require('nvim-treesitter-textobjects.repeatable_move').builtin_T_expr";
            options.expr = true;
          }
        ];
      in
      selectMaps
      ++ repeatMaps
      ++ ftMaps
      ++ [
        (mkSwap "<Leader>k" "swap_next" "@parameter.inner" "Swap next parameter")
        (mkSwap "<Leader>K" "swap_previous" "@parameter.outer" "Swap previous parameter")
      ]
      ++ [
        {
          mode = "n";
          key = "<Leader>c";
          action = "<CMD>TSContext toggle<CR>";
          options.desc = "Toggle treesitter context";
        }
      ];
  };
}
