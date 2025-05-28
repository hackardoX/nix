{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkDefault;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.suites.common;
in
{
  options = import (lib.snowfall.fs.get-file "shared/suites-options/common/default.nix") {
    inherit lib namespace;
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

      # services = {
      #  openssh = mkDefault enabled;
      # };

      system = {
        fonts = mkDefault enabled;
        # input = mkDefault enabled;
        interface = mkDefault enabled;
        networking = mkDefault enabled;
      };
    };

    # system.activationScripts.postActivation.text = lib.mkIf pkgs.stdenv.hostPlatform.isAarch64 ''
    #   echo "Installing Rosetta..."
    #   softwareupdate --install-rosetta --agree-to-license
    # '';
  };
}
