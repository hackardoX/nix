let
  octoPrefix = "<Leader>g";
  mkOctoKeymap =
    {
      key,
      action,
      mode,
      desc,
    }:
    {
      key = "${octoPrefix}${key}";
      action = "${action}<CR>";
      inherit mode;
      options = {
        inherit desc;
      };
    };
  octoKeymaps = map mkOctoKeymap [
    {
      mode = "n";
      key = "i";
      action = "<cmd>Octo issue list<CR>";
      desc = "List Issues";
    }
    {
      mode = "n";
      key = "I";
      action = "<cmd>Octo issue search<CR>";
      desc = "Search Issues";
    }
    {
      mode = "n";
      key = "p";
      action = "<cmd>Octo pr list<CR>";
      desc = "List PRs";
    }
    {
      mode = "n";
      key = "P";
      action = "<cmd>Octo pr search<CR>";
      desc = "Search PRs";
    }
    {
      mode = "n";
      key = "d";
      action = "<cmd>Octo discussion list<CR>";
      desc = "List Discussions";
    }
    {
      mode = "n";
      key = "n";
      action = "<cmd>Octo notification list<CR>";
      desc = "List Notifications";
    }
    {
      mode = "n";
      key = "r";
      action = "<cmd>Octo repo list<CR>";
      desc = "List Repos";
    }
  ];
  gitsignsPrefix = "<Leader>gs";
  gitsignsKeymaps = [
    {
      mode = "n";
      key = "${gitsignsPrefix}s";
      action.__raw = ''
        function()
          require("gitsigns").stage_hunk()
          vim.notify("Hunk staged", vim.log.levels.INFO, { title = "Gitsigns" })
        end
      '';
      options.desc = "Stage Hunk";
    }
    {
      mode = "n";
      key = "${gitsignsPrefix}u";
      action.__raw = ''
        function()
          require("gitsigns").undo_stage_hunk()
          vim.notify("Hunk unstaged", vim.log.levels.INFO, { title = "Gitsigns" })
        end
      '';
      options.desc = "Unstage Hunk";
    }
    {
      mode = "n";
      key = "${gitsignsPrefix}r";
      action = "<cmd>Gitsigns reset_hunk<CR>";
      options.desc = "Reset Hunk";
    }
    {
      mode = "n";
      key = "${gitsignsPrefix}p";
      action = "<cmd>Gitsigns preview_hunk<CR>";
      options.desc = "Preview Hunk";
    }
    {
      mode = "n";
      key = "${gitsignsPrefix}b";
      action = "<cmd>Gitsigns toggle_current_line_blame<CR>";
      options.desc = "Toggle Blame";
    }
  ];
in
{
  flake.modules.nixvim.dev = {
    plugins = {
      gitsigns = {
        # gitsigns documentation
        # See: https://github.com/lewis6991/gitsigns.nvim
        enable = true;
        lazyLoad.settings.event = [
          "BufReadPost"
          "BufNewFile"
        ];
        settings = {
          current_line_blame = true;
          current_line_blame_opts = {
            delay = 1000;
            ignore_blank_lines = true;
            ignore_whitespace = true;
            virt_text = true;
            virt_text_pos = "eol";
          };
          signcolumn = true;
          update_debounce = 200;
        };
      };
      octo = {
        enable = true;
        lazyLoad.settings.cmd = [ "Octo" ];
        settings = {
          picker = "telescope";
          enable_builtin = true;
          default_to_projects_v2 = true;
          default_merge_method = "squash";
          commands = {
            pr = {
              auto.__raw = ''
                function()
                  local gh = require "octo.gh"
                  local picker = require "octo.picker"
                  local utils = require "octo.utils"

                  local buffer = utils.get_current_buffer()

                  local auto_merge = function(number)
                    local cb = function()
                      utils.info "This PR will be auto-merged"
                    end
                    local opts = { cb = cb }
                    gh.pr.merge { number, auto = true, squash = true, opts = opts }
                  end

                  if not buffer or not buffer:isPullRequest() then
                    picker.prs {
                      cb = function(selected)
                        auto_merge(selected.obj.number)
                      end,
                    }
                  elseif buffer:isPullRequest() then
                    auto_merge(buffer.node.number)
                  end
                end
              '';
            };
          };
        };
      };
      which-key = {
        settings.spec = [
          {
            __unkeyed-1 = octoPrefix;
            group = "Octo (${toString (builtins.length octoKeymaps)} keymaps)";
          }
          {
            __unkeyed-1 = gitsignsPrefix;
            group = "Gitsigns (${toString (builtins.length gitsignsKeymaps)} keymaps)";
          }
        ];
      };
    };
    keymaps = octoKeymaps ++ gitsignsKeymaps;
  };
}
