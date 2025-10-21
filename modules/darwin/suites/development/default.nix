{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

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
      brews = [
        # "fuse-overlayfs"
      ];

      casks =
        lib.optionals cfg.aiEnable [ "ollamac" ]
        ++ lib.optionals cfg.mobileEnable [
          "android-studio"
          "expo-orbit"
        ];

      masApps = lib.mkIf config.${namespace}.tools.homebrew.masEnable (
        { }
        // lib.optionalAttrs cfg.mobileEnable {
          "Xcode" = 497799835;
        }
      );
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
            ssh = {
              inherit (cfg.ssh) knownHosts;
              enable = true;
            };
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
