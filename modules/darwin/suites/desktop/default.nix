{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.suites.desktop;
in
{
  options.${namespace}.suites.desktop = {
    enable = lib.mkEnableOption "common desktop configuration";
  };

  config = mkIf cfg.enable {
    homebrew = {
      casks = [
        # "bitwarden"
        # "ghostty"
        # "gpg-suite"
        # "hammerspoon"
        # "launchcontrol"
        # "sf-symbols"
        # "xquartz"
      ];

      masApps = mkIf config.${namespace}.tools.homebrew.masEnable {
        # "PopClip" = 445189367;
      };
    };
  };
}
