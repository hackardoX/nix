{ lib, ... }:
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
          provider_options = {
            codestral = {
              api_key = "MISTRAL_CODESTRAL_API_KEY";
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

  flake.modules.homeManager.dev = hmArgs: {
    home = {
      sessionVariables = {
        MISTRAL_CODESTRAL_API_KEY = lib.mkDefault "$(cat ${hmArgs.config.programs.onepassword-secrets.secretPaths.mistralCodestralApiKey})";
      };
    };

    programs.onepassword-secrets.secrets = {
      mistralCodestralApiKey = lib.mkDefault {
        path = ".secrets/.mistral_codestral_key";
        reference = "op://Development/Mistral API Key - Codestral/credential";
        group = "staff";
      };
    };
  };
}
