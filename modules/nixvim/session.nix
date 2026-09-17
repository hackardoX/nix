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
        # Extension registered in luaConfig.post (deferred with lazy load),
        # otherwise telescope would load_extension() at startup before the
        # plugin is on the runtimepath.
        enableTelescope = false;
        lazyLoad.settings = {
          cmd = [ "PersistedLoadLast" ];
          keys = [ "<Leader>qs" ];
        };
        luaConfig.post = "require('telescope').load_extension('persisted')";
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
