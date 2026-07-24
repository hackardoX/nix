{
  config,
  ...
}:
{
  flake.modules.homeManager.file-sync =
    hmArgs@{ pkgs, ... }:
    {
      imports = [ config.flake.modules.homeManager.rclone-sync ];

      programs.onepassword-secrets.secrets = {
        docsPassword = {
          path = ".secrets/rclone-sync/Documents/password";
          reference = "op://Development/Cloud Encryption/Docs/password";
          group = if pkgs.stdenv.isDarwin then "staff" else "wheel";
        };
        docsSalt = {
          path = ".secrets/rclone-sync/Documents/salt";
          reference = "op://Development/Cloud Encryption/Docs/salt";
          group = if pkgs.stdenv.isDarwin then "staff" else "wheel";
        };
      };

      services.rclone-sync.jobs = {
        docs-koofr = {
          localPath = "${hmArgs.config.home.homeDirectory}/Private Docs";
          destination = "Private Docs";
          providers = [
            "koofr"
          ];
          encrypted = true;
          salt = true;
          passwordFile = hmArgs.config.programs.onepassword-secrets.secretPaths.docsPassword;
          saltFile = hmArgs.config.programs.onepassword-secrets.secretPaths.docsSalt;
          schedule = "minutely";
        };
        docs-gdrive = {
          localPath = "${hmArgs.config.home.homeDirectory}/Private Docs";
          destination = "Private Docs";
          providers = [
            "gdrive"
          ];
          schedule = "minutely";
        };
      };
    };
}
