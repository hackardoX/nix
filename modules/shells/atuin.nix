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
            sync_frequency = "15m";
            dialect = "uk";
            key_path = config.programs.onepassword-secrets.secretPaths.atuinKey;
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
