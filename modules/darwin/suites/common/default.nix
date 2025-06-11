{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkDefault;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.suites.common;
in
{
  options = import (lib.snowfall.fs.get-file "modules/shared/suites-options/common/default.nix") {
    inherit config lib namespace;
  };

  config = mkIf cfg.enable {
    programs.zsh.enable = mkDefault true;

    homebrew = {
      brews = [
        # "bashdb"
      ];
    };

    ${namespace} = {
      home.extraOptions = {
        home.shellAliases = {
          # Prevent shell log command from overriding macos log
          log = ''command log'';
        };
      };

      nix = mkDefault enabled;

      programs.terminal.tools.ssh = mkDefault enabled;

      tools = {
        homebrew = mkDefault enabled;
      };

      services = {
        openssh = {
          enable = true;
          authorizedKeys = mkDefault cfg.openssh.authorizedKeys;
          authorizedKeyFiles = mkDefault cfg.openssh.authorizedKeyFiles;
        };
      };

      system = {
        fonts = mkDefault enabled;
        interface = mkDefault enabled;
        networking = mkDefault enabled;
      };
    };

    system.activationScripts.postActivation.text =
      lib.mkIf (pkgs.stdenv.hostPlatform.isAarch64 && cfg.rosettaEnable)
        ''
          echo "Installing Rosetta..."
          softwareupdate --install-rosetta --agree-to-license
        '';
  };
}
