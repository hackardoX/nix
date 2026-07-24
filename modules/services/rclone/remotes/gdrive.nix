{ lib, ... }: {
  flake.modules.homeManager.rclone = hmArgs: {
    programs.rclone.remotes = lib.mkIf (builtins.elem "gdrive" hmArgs.config.services.rclone.remotes) {
      gdrive = {
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
