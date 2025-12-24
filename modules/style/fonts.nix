let
  fontPackages = pkgs: [ pkgs.nerd-fonts.monaspace ];
in
{
  flake.modules = {
    darwin.base =
      { pkgs, ... }:
      {
        fonts.packages = fontPackages pkgs;
        system.defaults.NSGlobalDomain.AppleFontSmoothing = 1;
      };

    homeManager.base =
      { pkgs, ... }:
      {
        home.packages = fontPackages pkgs;
      };
  };
}
