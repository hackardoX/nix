{
  flake.modules.homeManager.base =
    { config, ... }:
    {
      programs = {
        atuin = {
          enableBashIntegration = true;
          enableFishIntegration = true;
          enable = true;
          enableZshIntegration = true;
          settings = {
            dialect = "uk";
            enter_accept = true;
            filter_mode = "workspace";
            inline_height = 12;
            key_path = config.programs.onepassword-secrets.secretPaths.atuinKey;
            keymap_mode = "auto";
            style = "auto";
            sync_frequency = "15m";
            workspaces = true;
          };
        };

        onepassword-secrets.secrets = {
          atuinKey = {
            path = ".secrets/.atuinkey";
            reference = "op://development/atuin/key";
            group = "staff";
          };
        };
      };
    };
}
