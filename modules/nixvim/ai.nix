{
  flake.modules.nixvim.dev = {
    plugins = {
      avante = {
        enable = true;
        settings = {
          # auto_suggestions_provider = "mistral_devstral";
          mode = "legacy";
          provider = "mistral_codestral";
          providers = {
            claude = {
              model = "claude-4-6-opus";
            };
            mistral_codestral = {
              __inherited_from = "openai";
              api_key_name = "MISTRAL_CODESTRAL_API_KEY";
              endpoint = "https://codestral.mistral.ai/v1";
              model = "codestral-latest";
              extra_request_body = {
                max_tokens = 4096;
              };
            };
            mistral_devstral = {
              __inherited_from = "openai";
              api_key_name = "MISTRAL_DEVSTRAL_API_KEY";
              endpoint = "https://api.mistral.ai/v1";
              model = "devstral-latest";
              extra_request_body = {
                max_tokens = 4096;
              };
            };
            moonshot = {
              endpoint = "https://api.moonshot.ai/v1";
              model = "kimi-k2.5";
              extra_request_body = {
                temperature = 0.75;
                max_tokens = 32768;
              };
            };
          };
          behaviour = {
            auto_suggestions = false;
            minimize_diff = true;
            enable_fastapply = true;
            mode = "legacy";
          };
          mappings = {
            submit = {
              normal = "<CR>";
              insert = "<CR>";
            };
            suggestion = {
              accept = "<Tab>";
              dismiss = "<C-]>";
            };
          };
          input = {
            provider = "dressing";
          };
        };
      };
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
      nui.enable = true;
      web-devicons.enable = true;
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
        ANTHROPIC_API_KEY = "$(cat ${hmArgs.config.programs.onepassword-secrets.secretPaths.mistralDevstralApiKey})";
        MISTRAL_CODESTRAL_API_KEY = "$(cat ${hmArgs.config.programs.onepassword-secrets.secretPaths.mistralCodestralApiKey})";
        MOONSHOT_API_KEY = "$(cat ${hmArgs.config.programs.onepassword-secrets.secretPaths.moonshotApiKey})";
        MORPH_API_KEY = "$(cat ${hmArgs.config.programs.onepassword-secrets.secretPaths.morphApiKey})";
        TAVILY_API_KEY = "$(cat ${hmArgs.config.programs.onepassword-secrets.secretPaths.tavilyApiKey})";
      };
      shellAliases = {
        avante = ''nvim -c "lua vim.defer_fn(function()require(\"avante.api\").zen_mode()end, 100)"'';
      };
    };

    programs.onepassword-secrets.secrets = {
      anthropicApiKey = {
        path = ".secrets/.antropic_key";
        reference = "op://Development/Anthropic API Key/credential";
        group = "staff";
      };
      mistralDevstralApiKey = {
        path = ".secrets/.mistral_key";
        reference = "op://Development/Mistral API Key - Devstral/credential";
        group = "staff";
      };
      mistralCodestralApiKey = {
        path = ".secrets/.mistral_codestral_key";
        reference = "op://Development/Mistral API Key - Codestral/credential";
        group = "staff";
      };
      moonshotApiKey = {
        path = ".secrets/.moonshot_key";
        reference = "op://Development/Moonshot API Key/credential";
        group = "staff";
      };
      morphApiKey = {
        path = ".secrets/.morph_key";
        reference = "op://Development/MorphLLM API Key/credential";
        group = "staff";
      };
      tavilyApiKey = {
        path = ".secrets/.tavily_key";
        reference = "op://Development/Tavily API Key/credential";
        group = "staff";
      };
    };
  };
}
