{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) types;
in
{
  ${namespace}.suites.common = {
    enable = lib.mkEnableOption "common configuration";
    rosettaEnable = lib.mkEnableOption "enable rosetta";
    openssh = {
      enable = lib.mkEnableOption "enable openssh";
      authorizedKeys = lib.mkOption {
        type = types.listOf types.str;
        description = "authorized keys for openssh";
        example = [ "ssh-rsa AAAAB..." ];
        default = [ ];
      };
      authorizedKeyFiles = lib.mkOption {
        type = types.listOf types.str;
        description = "authorized key files for openssh";
        example = [ "/home/user/.ssh/authorized_keys" ];
        default = [ ];
      };
    };
  };

  config.assertions = [
    {
      assertion =
        lib.length config.${namespace}.suites.common.openssh.authorizedKeys == 0
        || lib.length config.${namespace}.suites.common.openssh.authorizedKeyFiles == 0;
      message = "authorizedKeys and authorizedKeyFiles are mutually exclusive. Only one can be set.";
    }
  ];
}
