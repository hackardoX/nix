let
  dapPrefix = "<Leader>d";
  mkDapKeymap =
    {
      key,
      action,
      desc,
    }:
    {
      key = "${dapPrefix}${key}";
      mode = "n";
      inherit action;
      options = {
        inherit desc;
      };
    };
  dapKeymaps = map mkDapKeymap [
    {
      key = "c";
      action = "<CMD>DapContinue<CR>";
      desc = "Continue";
    }
    {
      key = "C";
      action.__raw = "function() require('dap').run_to_cursor() end";
      desc = "Run to cursor";
    }
    {
      key = "g";
      action.__raw = ''
        function() require('dap').goto_() end
      '';
      desc = "Go to line (no execute)";
    }
    {
      key = "o";
      action = "<CMD>DapStepOver<CR>";
      desc = "Step Over";
    }
    {
      key = "i";
      action = "<CMD>DapStepInto<CR>";
      desc = "Step Into";
    }
    {
      key = "O";
      action = "<CMD>DapStepOut<CR>";
      desc = "Step Out";
    }
    {
      key = "p";
      action = "<CMD>DapPause<CR>";
      desc = "Pause";
    }
    {
      key = "R";
      action.__raw = ''
        function() require('dap').restart() end
      '';
      desc = "Restart Debugging";
    }
    {
      key = "j";
      action.__raw = ''
        function() require('dap').down() end
      '';
      desc = "Down";
    }
    {
      key = "k";
      action.__raw = ''
        function() require('dap').up() end
      '';
      desc = "Up";
    }
    {
      key = "l";
      action.__raw = ''
        function() require('dap').run_last() end
      '';
      desc = "Run Last";
    }
    {
      key = "s";
      action.__raw = ''
        function() require('dap').session() end
      '';
      desc = "Session";
    }
    {
      key = "t";
      action.__raw = ''
        function() require('dap').terminate() end
      '';
      desc = "Terminate Debugging";
    }
    {
      key = "b";
      action = "<CMD>DapToggleBreakpoint<CR>";
      desc = "Toggle Breakpoint";
    }
    {
      key = "B";
      action.__raw = "function() require('dap').set_breakpoint(vim.fn.input('Condition: ')) end";
      desc = "Set Breakpoint";
    }
    {
      key = "r";
      action = "<CMD>DapToggleRepl<CR>";
      desc = "Toggle Repl";
    }
    {
      key = "l";
      action = "<CMD>DapShowLog<CR>";
      desc = "Show Log";
    }
  ];
in
{
  flake.modules.nixvim.dev = {
    plugins = {
      dap = {
        enable = true;
        luaConfig.pre = ''
          -- DEBUG LISTENERS
          require("dap").listeners.before.attach.dapui_config = function()
            require("dapui").open()
          end
          require("dap").listeners.before.launch.dapui_config = function()
            require("dapui").open()
          end
          require("dap").listeners.before.event_terminated.dapui_config = function()
            require("dapui").close()
          end
          require("dap").listeners.before.event_exited.dapui_config = function()
            require("dapui").close()
          end
        '';
      };
      dap-ui.enable = true;
      dap-virtual-text.enable = true;
      which-key = {
        settings.spec = [
          {
            __unkeyed-1 = dapPrefix;
            group = "Debug (${toString (builtins.length dapKeymaps)} keymaps)";
          }
        ];
      };
    };

    keymaps = dapKeymaps;
  };
}
