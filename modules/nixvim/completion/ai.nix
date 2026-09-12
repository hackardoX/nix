{ config, ... }:
{
  flake.modules.nixvim.dev = {
    plugins = {
      cmp.settings = {
        mapping = {
          "<C-S-Space>" = "cmp.mapping(require('minuet').make_cmp_map(), { 'i' })";
        };
      };
      minuet = {
        enable = true;
        settings = {
          provider = "openai_compatible";
          provider_options = {
            openai_compatible = {
              api_key = config.flake.meta.aiProviders.lumo.apiKeyEnv;
              name = "Proton Lumo";
              end_point = "${config.flake.meta.aiProviders.lumo.endpoint}/chat/completions";
              model = "lumo-lite";
              optional.thinking.type = "disabled";
            };
          };
          virtualtext = {
            auto_trigger_ft = [
              "c"
              "cpp"
              "cs"
              "java"
              "kotlin"
              "scala"
              "python"
              "ruby"
              "perl"
              "javascript"
              "typescript"
              "javascriptreact"
              "typescriptreact"
              "go"
              "rust"
              "swift"
              "lua"
              "vim"
              "sh"
              "bash"
              "zsh"
              "fish"
              "html"
              "css"
              "scss"
              "json"
              "toml"
              "yaml"
              "sql"
              "haskell"
              "elixir"
              "clojure"
              "ocaml"
              "erlang"
              "nix"
            ];
            keymap = {
              dismiss = "<C-e>";
            };
          };
        };
      };
    };
    keymaps = [
      {
        mode = [ "i" ];
        key = "<Tab>";
        action.__raw = ''
          function()
            local mv = require 'minuet.virtualtext'
            if mv.action.is_visible() then
              vim.defer_fn(mv.action.accept, 30)
              return ""
            elseif vim.snippet.active { direction = 1 } then
              return string.format('<Cmd>lua vim.snippet.jump(%d)<CR>', 1)
            else
              return '<tab>'
            end
          end
        '';
        options = {
          desc = "Accept minuet completion if available, jump snippet if active, otherwise insert tab.";
          expr = true;
          silent = true;
        };
      }
      {
        mode = [ "i" ];
        key = "<S-Tab>";
        action.__raw = ''
          function()
            local mv = require('minuet.virtualtext')
            if mv.action.is_visible() then
              mv.action.next()
            else
              return '<S-Tab>'
            end
          end
        '';
        options = {
          desc = "Cycle to next minuet suggestion, otherwise dedent";
          expr = true;
          silent = true;
        };
      }
    ];
  };
}
