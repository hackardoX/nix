{
  perSystem.pre-commit.settings.hooks.commitizen.enable = true;
  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.commitizen ];
    };
}
