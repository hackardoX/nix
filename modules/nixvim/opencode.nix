let
  opencodePrefix = "<Leader>a";
  mkOpencodeKeymap =
    {
      key,
      action,
      mode,
      desc,
    }:
    {
      key = "<Leader>a${key}";
      action = "<cmd>lua require('opencode').${action}<CR>";
      inherit mode;
      options = {
        inherit desc;
      };
    };
  opencodeKeymaps = map mkOpencodeKeymap [
    {
      key = "a";
      action = "ask('@this: ', { submit = true })";
      mode = [
        "n"
        "x"
      ];
      desc = "Ask";
    }
    {
      key = "?";
      action = "select()";
      mode = [
        "n"
        "x"
      ];
      desc = "Select action";
    }
    {
      key = "p";
      action = "prompt()";
      mode = [
        "n"
        "t"
      ];
      desc = "Open prompt";
    }
    {
      key = "o";
      action = "toggle()";
      mode = [
        "n"
        "t"
      ];
      desc = "Toggle opencode";
    }
  ];

in
{
  flake.modules.nixvim.dev = {
    plugins = {
      opencode.enable = true;
      which-key = {
        settings.spec = [
          {
            __unkeyed-1 = opencodePrefix;
            group = "Opencode (${toString (builtins.length opencodeKeymaps)} keymaps)";
          }
        ];
      };
    };
    keymaps = opencodeKeymaps;
  };
}
