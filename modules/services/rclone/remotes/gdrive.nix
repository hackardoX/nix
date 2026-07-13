{
  flake.modules.homeManager.base = hmArgs: {
    programs.rclone = {
      remotes.gdrive = {
        config = {
          type = "drive";
          scope = "drive";
        };

        secrets = {
          token = "${hmArgs.config.xdg.configHome}/rclone/gdrive-token.json";
        };
      };
    };
  };
}
