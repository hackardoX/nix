{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf optionals;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.suites.development;
in
{
  options.${namespace}.suites.development = {
    enable = mkEnableOption "common development configuration";
    dockerEnable = mkBoolOpt true "Whether or not to enable docker development configuration.";
    aiEnable = mkEnableOption "ai development configuration";
  };

  config = mkIf cfg.enable {
    homebrew = {
      casks = optionals cfg.dockerEnable [ "docker" ] ++ optionals cfg.aiEnable [ "ollamac" ];

      masApps = mkIf config.${namespace}.tools.homebrew.masEnable {
        # "Xcode" = 497799835;
      };
    };
  };
}
