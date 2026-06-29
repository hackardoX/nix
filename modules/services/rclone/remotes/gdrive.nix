{
  flake.modules.homeManager.base = hmArgs: {
    programs.rclone = {
      remotes.gdrive = {
        config = {
          type = "drive";
          scope = "drive";
        };

        secrets = {
          token = hmArgs.config.programs.onepassword-secrets.secretPaths.gdriveToken;
        };
      };
    };

    programs.onepassword-secrets.secrets.gdriveToken = {
      path = ".secrets/rclone/gdrive_token";
      reference = "op://Homelab/Rclone remotes/Google Drive/token";
    };
  };
}
