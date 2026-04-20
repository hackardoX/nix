{
  flake.modules.nixvim.dev = {
    plugins.dashboard = {
      enable = true;
      settings.config.shortcut = [
        {
          desc = "󰊳 Find File";
          group = "@property";
          action = "Telescope find_files";
          key = "f";
        }
        {
          desc = " Recent Files";
          group = "@property";
          action = "Telescope oldfiles";
          key = "r";
        }
        {
          desc = "󰈭 Find Word";
          group = "@property";
          action = "Telescope live_grep";
          key = "g";
        }
        {
          desc = "󱄼  Restore Session";
          group = "@property";
          action = "Persisted select";
          key = "s";
        }
      ];
    };
  };
}
