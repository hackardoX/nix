{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkOpt;

  # "https://github.com/brizzbuzz/opnix/blob/main/nix/hm-module.nix" # L17
  secretType = lib.types.submodule {
    options = {
      path = lib.mkOption {
        type = lib.types.str;
        description = ''
          Path where the secret will be stored, relative to home directory.
          For example: ".config/Yubico/u2f_keys" or ".ssh/id_rsa"
        '';
        example = ".config/Yubico/u2f_keys";
      };

      reference = lib.mkOption {
        type = lib.types.str;
        description = "1Password reference in the format op://vault/item/field";
        example = "op://Personal/ssh-key/private-key";
      };

      owner = lib.mkOption {
        type = lib.types.str;
        default = config.home.username;
        description = "User who owns the secret file (defaults to home user)";
      };

      group = lib.mkOption {
        type = lib.types.str;
        default = "users";
        description = "Group that owns the secret file";
      };

      mode = lib.mkOption {
        type = lib.types.str;
        default = "0600";
        description = "File permissions in octal notation";
        example = "0644";
      };
    };
  };
  cfg = config.${namespace}.security.opnix;
in
{

  options.${namespace}.security.opnix = {
    enable = lib.mkEnableOption "opnix";
    secrets = mkOpt (lib.types.attrsOf secretType) [ ] "List of secrets to manage with 1Password.";
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
