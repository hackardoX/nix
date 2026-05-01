let
  persistedPrefix = "<Leader>q";
  mkPersistedKeymap =
    {
      key,
      action,
      mode,
      desc,
    }:
    {
      key = "${persistedPrefix}${key}";
      action = "<CMD>${action}<CR>";
      inherit mode;
      options = {
        inherit desc;
      };
    };
  persistedKeymaps = map mkPersistedKeymap [
    {
      mode = "n";
      key = "s";
      action = "Telescope persisted";
      desc = "Select session (Telescope)";
    }
    {
      mode = "n";
      key = "l";
      action = "PersistedLoadLast";
      desc = "Load last session";
    }
  ];
in
{
  flake.modules.nixvim.dev = {
    plugins = {
      persisted = {
        enable = true;
        enableTelescope = true;
        settings = {
          autoload = false;
          use_git_branch = true;
        };
      };
      which-key = {
        settings.spec = [
          {
            __unkeyed-1 = persistedPrefix;
            group = "Sessions (${toString (builtins.length persistedKeymaps)} keymaps)";
          }
        ];
      };
    };
    keymaps = persistedKeymaps;
  };
}
