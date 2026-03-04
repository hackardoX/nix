{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem = {
    treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        prettier.enable = true;
        shfmt.enable = true;
      };
      settings = {
        on-unmatched = "fatal";
        global.excludes = [
          "*.jpg"
          "*.png"
          ".github/CODEOWNERS"
          "*.zsh" # TODO: Find a formatter or transform to nix file
          "LICENSE"
        ];
      };
    };

    pre-commit.settings.hooks.treefmt.enable = true;
  };

  flake.modules.nixvim.dev = {
    plugins.conform-nvim = {
      enable = true;
      settings = {
        format_on_save = inputs.nixvim.lib.nixvim.mkRaw ''
          function(bufnr)
            if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
              return
            end
            return { timeout_ms = 500, lsp_format = "fallback" }
          end
        '';
      };
    };
    keymaps = [
      {
        key = "<leader>t";
        options.desc = "Toggle autoformatting";
        action = inputs.nixvim.lib.nixvim.mkRaw ''
          function()
            vim.g.disable_autoformat = not vim.g.disable_autoformat
            local message = vim.g.disable_autoformat and "Autoformatting is off" or "Autoformatting is on"
            vim.notify(message, vim.log.levels.INFO)
          end
        '';
      }
      {
        mode = "n";
        key = "<space>f";
        action.__raw = ''
          function()
            require("conform").format({ async = true, lsp_format = "fallback" })
          end
        '';
        options.desc = "Format buffer";
      }
    ];
  };
}
