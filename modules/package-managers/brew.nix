{ inputs, ... }:
{
  flake.modules.darwin.homebrew =
    { config, ... }:
    {
      imports = [
        inputs.nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            user = config.system.primaryUser;
            taps = {
              "homebrew/homebrew-core" = inputs.homebrew-core;
              "homebrew/homebrew-cask" = inputs.homebrew-cask;
              "hackardox/homebrew-formulas" = inputs.custom-homebrew-formulas;
              "anomalyco/homebrew-tap" = inputs.hex-homebrew-tap;
            };
            mutableTaps = false;
            autoMigrate = true;
          };
        }
      ];

      environment.variables = {
        HOMEBREW_BAT = "1";
        HOMEBREW_NO_ANALYTICS = "1";
        HOMEBREW_NO_INSECURE_REDIRECT = "1";
      };

      homebrew = {
        enable = true;

        casks = [ "anomalyco/tap/hex" ];

        global = {
          brewfile = true;
          autoUpdate = true;
        };

        onActivation = {
          autoUpdate = true;
          # cleanup = "zap";
          upgrade = true;
          # extraFlags = [
          #   "--force-cleanup"
          # ];
        };

        taps = builtins.attrNames config.nix-homebrew.taps;
      };
    };
}
