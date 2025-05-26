{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.suites.business;
in
{
  options.${namespace}.suites.business = {
    enable = lib.mkEnableOption "business configuration";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ ];

    ${namespace} = {
      programs = {
        terminal = {
          tools = {
            _1password-cli = lib.mkDefault enabled;
          };
        };
      };
    };
  };
}
