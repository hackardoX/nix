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
          before_cursor_filter_length = 16;
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

  flake.modules.nixvim.hackardo = {
    plugins.minuet.settings.provider_options = {
      codestral = {
        api_key = "MISTRAL_CODESTRAL_API_KEY";
      };
    };
  };

  flake.modules.homeManager.hackardo = hmArgs: {
    home.sessionVariables.MISTRAL_CODESTRAL_API_KEY = "$(cat ${
      hmArgs.config.sops.secrets."ai/mistral_codestral_api_key".path
    })";

    sops.secrets."ai/mistral_codestral_api_key" = {
      path = "${hmArgs.config.home.homeDirectory}/.secrets/.mistral_codestral_key";
    };
  };

  flake.modules.nixvim.aaccardo = {
    plugins.minuet.settings.provider_options = {
      lumo = {
        api_key = "LUMO_API_KEY";
      };
    };
  };

  flake.modules.homeManager.aaccardo = hmArgs: {
    home.sessionVariables.LUMO_CODESTRAL_API_KEY = "$(cat ${
      hmArgs.config.sops.secrets."ai/lumo_api_key".path
    })";

    sops.secrets."ai/lumo_api_key" = {
      path = "${hmArgs.config.home.homeDirectory}/.secrets/.lumo_key";
    };
  };
}
