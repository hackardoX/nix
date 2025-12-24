{
  flake.modules.homeManager.base =
    { config, ... }:
    {
      programs.atuin = {
        enableBashIntegration = true;
        enableFishIntegration = true;
        enable = true;
        enableZshIntegration = true;
        settings = {
          sync_frequency = "15m";
          dialect = "uk";
          key_path = config.programs.onepassword-secrets.secretPaths.atuinKey.path; # TODO
        };
      };
    };

  security = {
    opnix.secrets = {
      atuinKey = {
        path = ".secrets/.atuinKey";
        reference = "op://Development/Atuin/credential";
        group = "staff";
      };
    };
  };
}
