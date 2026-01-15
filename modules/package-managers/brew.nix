{ inputs, ... }:
{
  flake.modules.darwin.laptop =
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

        global = {
          brewfile = true;
          autoUpdate = true;
        };

        onActivation = {
          autoUpdate = true;
          cleanup = "zap";
          upgrade = true;
        };

        taps = builtins.attrNames config.nix-homebrew.taps;
      };
    };
}
