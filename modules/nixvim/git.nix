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
    keymaps = [
      {
        mode = "n";
        key = "<leader>oi";
        action = "<cmd>Octo issue list<CR>";
        options.desc = "List Issues";
      }
      {
        mode = "n";
        key = "<leader>oI";
        action = "<cmd>Octo issue search<CR>";
        options.desc = "Search Issues";
      }
      {
        mode = "n";
        key = "<leader>op";
        action = "<cmd>Octo pr list<CR>";
        options.desc = "List PRs";
      }
      {
        mode = "n";
        key = "<leader>oP";
        action = "<cmd>Octo pr search<CR>";
        options.desc = "Search PRs";
      }
      {
        mode = "n";
        key = "<leader>od";
        action = "<cmd>Octo discussion list<CR>";
        options.desc = "List Discussions";
      }
      {
        mode = "n";
        key = "<leader>on";
        action = "<cmd>Octo notification list<CR>";
        options.desc = "List Notifications";
      }
      {
        mode = "n";
        key = "<leader>or";
        action = "<cmd>Octo repo list<CR>";
        options.desc = "List Repos";
      }
    ];
  };
}
