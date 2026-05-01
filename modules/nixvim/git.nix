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
in
{
  flake.modules.nixvim.dev = {
    plugins = {
      gitblame = {
        enable = true;
        settings.enabled = false;
      };
      gitgutter.enable = true;
      octo = {
        enable = true;
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
        ];
      };
    };
    keymaps = octoKeymaps;
  };
}
