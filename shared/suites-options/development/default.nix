{
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption types;
  inherit (lib.${namespace}) mkBoolOpt;
in
{
  ${namespace}.suites.development = {
    enable = mkEnableOption "common development configuration";
    aiEnable = mkEnableOption "ai development configuration";
    dockerEnable = mkEnableOption "docker development configuration";
    nixEnable = mkEnableOption "nix development configuration";
    sqlEnable = mkEnableOption "sql development configuration";
    git = {
      user = mkOption {
        type = types.str;
        example = "johndoe";
        description = "Git username for commits";
      };
      email = mkOption {
        type = types.str;
        example = "john@example.com";
        description = "Git email for commits";
      };
    };
    ssh = {
      authorizedKeys = mkOption {
        type = types.listOf types.str;
        example = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC..."
        ];
        description = "List of SSH public keys to be added to authorized_keys";
      };
    };
  };
}
