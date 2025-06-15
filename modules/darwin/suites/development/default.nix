{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf optionals;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.suites.development;
in
{
  options =
    import (lib.snowfall.fs.get-file "modules/shared/suites-options/development/default.nix")
      {
        inherit lib namespace;
      };

  config = mkIf cfg.enable {
    homebrew = {
      casks =
        optionals (cfg.containerization.enable && builtins.elem "docker" cfg.containerization.variants) [
          "docker"
        ]
        ++ optionals cfg.aiEnable [ "ollamac" ];

      masApps = mkIf config.${namespace}.tools.homebrew.masEnable {
        # "Xcode" = 497799835;
      };
    };

    ${namespace} = {
      programs = {
        terminal = {
          tools = {
            ssh = enabled;
          };
        };
      };
    };
  };
}
