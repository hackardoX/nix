{
  flake.modules.nixvim.dev = {
    extraFiles."lua/dev/tooling_info.lua".source = ./tooling_info.lua;

    userCommands.ToolingInfo = {
      desc = "Show current buffer tooling details";
      command.__raw = ''
        function()
          require("dev.tooling_info").notify(0)
        end
      '';
    };
  };
}
