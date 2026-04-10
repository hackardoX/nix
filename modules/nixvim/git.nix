let
  mkOctoKeymap =
    {
      key,
      action,
      mode,
      desc,
    }:
    {
      key = "<Leader>g${key}";
      action = "${action}<CR>";
      inherit mode;
      options = {
        inherit desc;
      };
    };
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
          # gh_env.__raw = ''
          #   function()
          #     local github_token = require('op.api').item.get({ 'GitHub Personal Access Token', '--fields', 'token' })[1]
          #     if not github_token or not vim.startswith(github_token, 'ghp_') then
          #       error('Failed to get GitHub token.')
          #     end
          #     return { GITHUB_TOKEN = github_token }
          #   end
          # '';
        };
      };
    };
    keymaps = map mkOctoKeymap [
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
  };
}
