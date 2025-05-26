{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.suites.business;
in
{
  options.${namespace}.suites.business = {
    enable = lib.mkEnableOption "business configuration";
  };

  config = mkIf cfg.enable {
    homebrew = {
      casks = [
        "1password"
        "1password-cli"
        # "fantastical"
        # "libreoffice"
        "microsoft-excel"
        "microsoft-powerpoint"
        "microsoft-word"
        # "meetingbar"
        # "microsoft-teams"
        # "obsidian"
      ];

      masApps = mkIf config.${namespace}.tools.homebrew.masEnable {
        "1Password for Safari" = 1569813296;
        "Keynote" = 409183694;
        # "Microsoft OneNote" = 784801555;
        # "Notability" = 360593530;
      };
    };
  };
}
