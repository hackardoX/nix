{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkOpt;

  cfg = config.${namespace}.security.opnix;
in
{
  options.${namespace}.security.opnix = {
    enable = lib.mkEnableOption "opnix";
    secrets = mkOpt (lib.types.listOf (
      lib.types.attrsOf lib.types.str
    )) [ ] "List of secrets to manage with 1Password.";
  };

  config = lib.mkIf cfg.enable {
    programs = {
      onepassword-secrets = {
        enable = true;
        inherit (cfg) secrets;
      };
    };
  };
}
