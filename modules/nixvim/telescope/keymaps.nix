let
  telescopePrefix = "<Leader>f";
  mkTelescopeKeymap =
    {
      key,
      action,
    }:
    {
      name = "${telescopePrefix}${key}";
      value = {
        inherit action;
      };
    };
  telescopeKeymaps = builtins.listToAttrs (
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
        key = "w";
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
  multiopen = {
    __raw = ''
      function(prompt_bufnr)
        local picker = require('telescope.actions.state').get_current_picker(prompt_bufnr)
        local multi = picker:get_multi_selection()
        if not vim.tbl_isempty(multi) then
          require('telescope.actions').close(prompt_bufnr)
          for _, j in pairs(multi) do
            if j.path ~= nil then
              if j.lnum ~= nil then
                vim.cmd(string.format("%s +%s %s", "edit", j.lnum, j.path))
              else
                vim.cmd(string.format("%s %s", "edit", j.path))
              end
            end
          end
        else
          require('telescope.actions').select_default(prompt_bufnr)
        end
      end
    '';
  };
in
{
  flake.modules.nixvim.dev = {
    plugins = {
      which-key = {
        settings.spec = [
          {
            __unkeyed-1 = telescopePrefix;
            group = "Telescope (${toString (builtins.length (builtins.attrNames telescopeKeymaps))} keymaps)";
          }
        ];
      };
      telescope = {
        keymaps = telescopeKeymaps;
        settings.defaults.mappings = {
          n = {
            "<c-d>" = "delete_buffer";
            "<CR>" = multiopen;
          };
          i = {
            "<c-d>" = "delete_buffer";
            "<CR>" = multiopen;
          };
        };
      };
    };
  };
}
