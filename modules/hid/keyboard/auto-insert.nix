{ lib, ... }:
{
  flake.modules.homeManager.base =
    { pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      targets.darwin = {
        defaults = {
          NSGlobalDomain = {
            NSAutomaticCapitalizationEnabled = false;
            NSAutomaticDashSubstitutionEnabled = false;
            NSAutomaticQuoteSubstitutionEnabled = false;
            NSAutomaticPeriodSubstitutionEnabled = false;
            NSAutomaticSpellingCorrectionEnabled = false;
          };
        };
      };
    };
}
