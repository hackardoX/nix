{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
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
      casks = lib.optionals cfg.aiEnable [ "ollamac" ];

      masApps = mkIf config.${namespace}.tools.homebrew.masEnable {
        # "Xcode" = 497799835;
      };
    };

    ${namespace} = {
      programs = {
        containerization = {
          orbstack = {
            enable = cfg.containerization.enable && builtins.elem "orbstack" cfg.containerization.variants;
          };
          podman = {
            enable = cfg.containerization.enable && builtins.elem "podman" cfg.containerization.variants;
            provider = "applehv";
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
