{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.suites.business;
in
{
  options = import (lib.snowfall.fs.get-file "modules/shared/suites-options/business/default.nix") {
    inherit lib namespace;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ ];

    ${namespace} = {
      programs = {
        terminal = {
          tools = {
            _1password = {
              enable = true;
              enableSshSocket = true;
            };
          };
        };
      };
    };
  };
}
