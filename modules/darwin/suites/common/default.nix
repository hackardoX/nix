{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.suites.common;
in
{
  options = import (lib.snowfall.fs.get-file "modules/shared/suites-options/common/default.nix") {
    inherit config lib namespace;
  };

  config = mkIf cfg.enable {
    programs.zsh.enable = true;

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

      nix = enabled;

      programs.terminal.tools.ssh = enabled;

      tools = {
        homebrew = {
          enable = true;
          masEnable = true;
        };
      };

      services = {
        openssh = {
          enable = true;
          inherit (cfg.openssh) authorizedKeys;
          inherit (cfg.openssh) authorizedKeyFiles;
        };
      };

      system = {
        fonts = enabled;
        interface = enabled;
        networking = enabled;
      };
    };

    system.activationScripts.postActivation.text =
      lib.mkIf (pkgs.stdenv.hostPlatform.isAarch64 && cfg.rosetta.enable)
        ''
          echo "Installing Rosetta..."
          softwareupdate --install-rosetta --agree-to-license
        '';
  };
}
