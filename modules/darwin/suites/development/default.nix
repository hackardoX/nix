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
        containerization = {
          podman = {
            enable = cfg.containerization.enable && builtins.elem "podman" cfg.containerization.variants;
            overrideDockerSocket = true;
            autoStart = true;
          };
        };

        terminal = {
          tools = {
            ssh = enabled;
          };
        };
      };

      security = {
        _1password = {
          openv = true;
        };
      };
    };
  };
}
